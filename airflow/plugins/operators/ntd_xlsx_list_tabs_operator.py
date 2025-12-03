import io
from typing import Sequence

import openpyxl

from airflow.models import BaseOperator
from airflow.models.taskinstance import Context
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class NTDXLSXListTabsOperator(BaseOperator):
    template_fields: Sequence[str] = (
        "source_bucket",
        "source_path",
        "gcp_conn_id",
    )

    def __init__(
        self,
        source_bucket: str,
        source_path: str,
        gcp_conn_id: str = "google_cloud_default",
        **kwargs,
    ) -> None:
        super().__init__(**kwargs)

        self.source_bucket = source_bucket
        self.source_path = source_path
        self.gcp_conn_id = gcp_conn_id

    def gcs_hook(self) -> GCSHook:
        return GCSHook(gcp_conn_id=self.gcp_conn_id)

    def source_name(self) -> str:
        return self.source_bucket.replace("gs://", "")

    def source(self) -> bytes:
        return self.gcs_hook().download(
            bucket_name=self.source_name(),
            object_name=self.source_path,
        )

    def workbook(self) -> bytes:
        return openpyxl.load_workbook(filename=io.BytesIO(self.source()))

    def execute(self, context: Context) -> str:
        workbook = self.workbook()
        return [
            {"tab": s, "source_path": self.source_path} for s in workbook.sheetnames
        ]
