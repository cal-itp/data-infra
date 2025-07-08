import json
import os
from datetime import datetime
from typing import Sequence

from src.bigquery_cleaner import BigQueryCleaner

from airflow.hooks.http_hook import HttpHook
from airflow.models import BaseOperator, DagRun
from airflow.models.taskinstance import Context
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class NTDObjectPath:
    def __init__(self, product: str, year: str) -> None:
        self.product = product
        self.year = year

    def resolve(self, logical_date: datetime) -> str:
        return os.path.join(
            self.product,
            self.year,
            f"dt={logical_date.date().isoformat()}",
            f"execution_ts={logical_date.isoformat()}",
            f"{self.year}__{self.product}.jsonl.gz",
        )


class NTDToGCSOperator(BaseOperator):
    template_fields: Sequence[str] = (
        "bucket",
        "product",
        "year",
        "endpoint",
        "http_conn_id",
        "gcp_conn_id",
    )

    def __init__(
        self,
        bucket: str,
        product: str,
        year: str,
        endpoint: str,
        http_conn_id: str = "http_default",
        gcp_conn_id: str = "google_cloud_default",
        **kwargs,
    ) -> None:
        super().__init__(**kwargs)

        self.bucket = bucket
        self.product = product
        self.year = year
        self.endpoint = endpoint
        self.http_conn_id = http_conn_id
        self.gcp_conn_id = gcp_conn_id

    def bucket_name(self) -> str:
        return self.bucket.replace("gs://", "")

    def object_path(self) -> NTDObjectPath:
        return NTDObjectPath(product=self.product, year=self.year)

    def gcs_hook(self) -> GCSHook:
        return GCSHook(gcp_conn_id=self.gcp_conn_id)

    def http_hook(self) -> HttpHook:
        return HttpHook(method="GET", http_conn_id=self.http_conn_id)

    def cleaned_rows(self) -> list:
        result = self.http_hook().run(self.endpoint).json()
        return [
            json.dumps(x, separators=(",", ":"))
            for x in BigQueryCleaner(result).clean()
        ]

    def execute(self, context: Context) -> str:
        dag_run: DagRun = context["dag_run"]
        object_name: str = self.object_path().resolve(dag_run.logical_date)
        self.gcs_hook().upload(
            bucket_name=self.bucket_name(),
            object_name=object_name,
            data="\n".join(self.cleaned_rows()),
            mime_type="application/jsonl",
            gzip=True,
        )
        return os.path.join(self.bucket, object_name)
