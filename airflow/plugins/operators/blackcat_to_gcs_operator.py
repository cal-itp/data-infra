import json
import os
from datetime import datetime
from typing import Sequence

from src.bigquery_cleaner import BigQueryCleaner

from airflow.models import BaseOperator, DagRun
from airflow.models.taskinstance import Context
from airflow.providers.google.cloud.hooks.gcs import GCSHook
from airflow.providers.http.hooks.http import HttpHook


class BlackCatObjectPath:
    def __init__(self, api_name: str, file_name: str) -> None:
        self.api_name = api_name
        self.file_name = file_name

    def resolve(self, logical_date: datetime) -> str:
        return os.path.join(
            self.api_name,
            f"year={logical_date.date().year}",
            f"dt={logical_date.date().isoformat()}",
            f"ts={logical_date.isoformat()}",
            f"{self.file_name}.jsonl.gz",
        )


class BlackCatToGCSOperator(BaseOperator):
    template_fields: Sequence[str] = (
        "bucket",
        "endpoint",
        "api_name",
        "file_name",
        "http_conn_id",
        "gcp_conn_id",
    )

    def __init__(
        self,
        bucket: str,
        endpoint: str,
        api_name: str,
        file_name: str,
        http_conn_id: str = "http_blackcat",
        gcp_conn_id: str = "google_cloud_default",
        **kwargs,
    ) -> None:
        super().__init__(**kwargs)

        self.bucket = bucket
        self.endpoint = endpoint
        self.api_name = api_name
        self.file_name = file_name
        self.http_conn_id = http_conn_id
        self.gcp_conn_id = gcp_conn_id

    def bucket_name(self) -> str:
        return self.bucket.replace("gs://", "")

    def object_path(self) -> BlackCatObjectPath:
        return BlackCatObjectPath(api_name=self.api_name, file_name=self.file_name)

    def gcs_hook(self) -> GCSHook:
        return GCSHook(gcp_conn_id=self.gcp_conn_id)

    def http_hook(self) -> HttpHook:
        return HttpHook(method="GET", http_conn_id=self.http_conn_id)

    def cleaned_rows(self) -> list:
        result = self.http_hook().run(endpoint=self.endpoint).json()
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
