import csv
import io
import os
from typing import Sequence

from airflow.models import BaseOperator
from airflow.models.taskinstance import Context
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class ItemsToGCSOperator(BaseOperator):
    template_fields: Sequence[str] = (
        "bucket_name",
        "object_name",
        "items",
        "gcp_conn_id",
    )

    def __init__(
        self,
        bucket_name: str,
        object_name: str,
        items: list[dict],
        gcp_conn_id: str = "google_cloud_default",
        **kwargs,
    ):
        super().__init__(**kwargs)

        self.bucket_name = bucket_name
        self.object_name = object_name
        self.items = items
        self.gcp_conn_id = gcp_conn_id

    def gcs_hook(self) -> GCSHook:
        return GCSHook(gcp_conn_id=self.gcp_conn_id)

    def csv(self) -> str:
        output = io.StringIO()
        writer = csv.DictWriter(output, fieldnames=self.items[0].keys(), delimiter="\t")
        writer.writeheader()
        writer.writerows(self.items)
        return output.getvalue()

    def execute(self, context: Context) -> str:
        self.gcs_hook().upload(
            bucket_name=self.bucket_name.replace("gs://", ""),
            object_name=self.object_name,
            data=self.csv(),
            mime_type="text/csv",
        )
        return os.path.join(self.bucket_name, self.object_name)
