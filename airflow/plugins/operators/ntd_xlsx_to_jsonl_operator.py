import csv
import io
import json
from typing import Sequence

import openpyxl

from airflow.models import BaseOperator
from airflow.models.taskinstance import Context
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class NTDXLSXToJSONLOperator(BaseOperator):
    template_fields: Sequence[str] = (
        "tab",
        "source_bucket",
        "source_path",
        "destination_bucket",
        "destination_path",
        "gcp_conn_id",
    )

    def __init__(
        self,
        tab: str,
        source_bucket: str,
        source_path: str,
        destination_bucket: str,
        destination_path: str,
        gcp_conn_id: str = "google_cloud_default",
        **kwargs,
    ) -> None:
        super().__init__(**kwargs)

        self._gcs_hook = None
        self.tab = tab
        self.source_bucket = source_bucket
        self.source_path = source_path
        self.destination_bucket = destination_bucket
        self.destination_path = destination_path
        self.gcp_conn_id = gcp_conn_id

    def gcs_hook(self) -> GCSHook:
        return GCSHook(gcp_conn_id=self.gcp_conn_id)

    def destination_name(self) -> str:
        return self.destination_bucket.replace("gs://", "")

    def source_name(self) -> str:
        return self.source_bucket.replace("gs://", "")

    def source(self) -> bytes:
        return self.gcs_hook().download(
            bucket_name=self.source_name(),
            object_name=self.source_path,
        )

    def rows(self) -> bytes:
        workbook = openpyxl.load_workbook(filename=io.BytesIO(self.source()))
        csv_file = io.StringIO()
        writer = csv.writer(csv_file)
        for row in workbook[self.tab].rows:
            writer.writerow([cell.value for cell in row])
        csv_file.seek(0)
        return csv.DictReader(csv_file)

    def execute(self, context: Context) -> str:
        self.gcs_hook().upload(
            bucket_name=self.destination_name(),
            object_name=self.destination_path,
            data="\n".join([json.dumps(r, separators=(",", ":")) for r in self.rows()]),
            mime_type="application/jsonl",
            gzip=True,
        )
        return {"destination_path": self.destination_path}
