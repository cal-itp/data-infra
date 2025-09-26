import json
import os
from typing import Sequence

from hooks.kuba_hook import KubaHook
from src.kuba_cleaner import KubaCleaner

from airflow.hooks.base import BaseHook
from airflow.models import BaseOperator
from airflow.models.connection import Connection
from airflow.models.taskinstance import Context
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class JsonlFormatter:
    def __init__(self, json, cleaner) -> None:
        self.json = json
        self.cleaner = cleaner

    def format(self) -> str:
        return "\n".join(
            [
                json.dumps(x, separators=(",", ":"))
                for x in self.cleaner(self.json).clean()
            ]
        )


class KubaToGCSOperator(BaseOperator):
    template_fields: Sequence[str] = (
        "bucket",
        "endpoint",
        "object_path",
        "parameters",
        "http_conn_id",
        "gcp_conn_id",
    )

    def __init__(
        self,
        bucket: str,
        endpoint: str,
        parameters: dict,
        object_path: str,
        http_conn_id: str = "http_kuba",
        gcp_conn_id: str = "google_cloud_default",
        **kwargs,
    ) -> None:
        super().__init__(**kwargs)

        self.bucket = bucket
        self.endpoint = endpoint
        self.parameters = parameters
        self.object_path = object_path
        self.http_conn_id = http_conn_id
        self.gcp_conn_id = gcp_conn_id

    def bucket_name(self) -> str:
        return self.bucket.replace("gs://", "")

    def object_name(self) -> str:
        schema = self.kuba_connection().schema
        return f"{self.object_path}/operator_identifier={schema}/results.jsonl.gz"

    def gcs_hook(self) -> GCSHook:
        return GCSHook(gcp_conn_id=self.gcp_conn_id)

    def kuba_connection(self) -> Connection:
        return BaseHook.get_connection(self.http_conn_id)

    def kuba_hook(self) -> KubaHook:
        return KubaHook(method="GET", http_conn_id=self.http_conn_id)

    def execute(self, context: Context) -> str:
        response = self.kuba_hook().run(endpoint=self.endpoint, data=self.parameters)
        self.gcs_hook().upload(
            bucket_name=self.bucket_name(),
            object_name=self.object_name(),
            data=JsonlFormatter(json=response["List"], cleaner=KubaCleaner).format(),
            mime_type="application/jsonl",
            gzip=True,
        )
        return os.path.join(self.bucket, self.object_name())
