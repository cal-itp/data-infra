import json
import os
from datetime import datetime
from typing import Sequence

from hooks.kuba_hook import KubaHook
from src.kuba_cleaner import KubaCleaner

from airflow.models import BaseOperator, DagRun
from airflow.models.taskinstance import Context
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class KubaObjectPath:
    def __init__(self, product: str) -> None:
        self.product = product

    def resolve(self, logical_date: datetime) -> str:
        return os.path.join(
            self.product,
            f"dt={logical_date.date().isoformat()}",
            f"ts={logical_date.isoformat()}",
            "results.jsonl.gz",
        )


class KubaToGCSOperator(BaseOperator):
    template_fields: Sequence[str] = (
        "bucket",
        "endpoint",
        "product",
        "parameters",
        "http_conn_id",
        "gcp_conn_id",
    )

    def __init__(
        self,
        bucket: str,
        endpoint: str,
        parameters: dict,
        product: str,
        http_conn_id: str = "http_kuba",
        gcp_conn_id: str = "google_cloud_default",
        **kwargs,
    ) -> None:
        super().__init__(**kwargs)

        self.bucket = bucket
        self.endpoint = endpoint
        self.parameters = parameters
        self.product = product
        self.http_conn_id = http_conn_id
        self.gcp_conn_id = gcp_conn_id

    def bucket_name(self) -> str:
        return self.bucket.replace("gs://", "")

    def object_path(self) -> KubaObjectPath:
        return KubaObjectPath(product=self.product)

    def gcs_hook(self) -> GCSHook:
        return GCSHook(gcp_conn_id=self.gcp_conn_id)

    def kuba_hook(self) -> KubaHook:
        return KubaHook(method="GET", http_conn_id=self.http_conn_id)

    def cleaned_rows(self) -> list:
        result = self.kuba_hook().run(endpoint=self.endpoint, data=self.parameters)
        return [
            json.dumps(x, separators=(",", ":"))
            for x in KubaCleaner(result["List"]).clean()
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
