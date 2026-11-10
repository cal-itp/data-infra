import json
import os
from typing import Sequence

from hooks.soda_hook import SODAHook
from src.bigquery_cleaner import BigQueryCleaner

from airflow.models import BaseOperator
from airflow.models.taskinstance import Context
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class JsonlFormatter:
    def __init__(self, json) -> None:
        self.json = json

    def cleaner(self) -> BigQueryCleaner:
        return BigQueryCleaner(self.json)

    def format(self) -> str:
        return "\n".join(
            [json.dumps(x, separators=(",", ":")) for x in self.cleaner().clean()]
        )


class SODAToGCSOperator(BaseOperator):
    template_fields: Sequence[str] = (
        "resource",
        "bucket_name",
        "object_path",
        "http_conn_id",
        "gcp_conn_id",
    )

    def __init__(
        self,
        resource: str,
        bucket_name: str,
        object_path: str,
        http_conn_id: str = "http_ntd",
        gcp_conn_id: str = "google_cloud_default",
        **kwargs,
    ) -> None:
        super().__init__(**kwargs)

        self.resource = resource
        self.bucket_name = bucket_name
        self.object_path = object_path
        self.http_conn_id = http_conn_id
        self.gcp_conn_id = gcp_conn_id

    def gcs_hook(self) -> GCSHook:
        return GCSHook(gcp_conn_id=self.gcp_conn_id)

    def soda_hook(self) -> SODAHook:
        return SODAHook(method="GET", http_conn_id=self.http_conn_id)

    def execute(self, context: Context) -> str:
        paths: list[str] = []
        for page in range(1, self.soda_hook().total_pages(self.resource)):
            response = self.soda_hook().page(self.resource, page=page)
            data = JsonlFormatter(response).format()
            object_name = f"{self.object_path}/page-{page:04}.jsonl.gz"
            paths.append(os.path.join(self.bucket_name, object_name))
            self.gcs_hook().upload(
                data=data,
                bucket_name=self.bucket_name.replace("gs://", ""),
                object_name=object_name,
                mime_type="application/jsonl",
                gzip=True,
            )
        return paths
