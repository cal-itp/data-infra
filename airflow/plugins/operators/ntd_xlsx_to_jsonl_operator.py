import csv
import io
import json
from typing import Sequence

import openpyxl
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


class NTDXLSXToJSONLOperator(BaseOperator):
    template_fields: Sequence[str] = (
        "type",
        "year",
        "tab_name",
        "source_bucket",
        "source_path",
        "destination_bucket",
        "destination_path",
        "gcp_conn_id",
    )

    def __init__(
        self,
        type: str,
        year: str,
        tab_name: str,
        source_bucket: str,
        source_path: str,
        destination_bucket: str,
        destination_path: str,
        gcp_conn_id: str = "google_cloud_default",
        **kwargs,
    ) -> None:
        super().__init__(**kwargs)

        self._gcs_hook = None
        self.type: str = type
        self.year: str = year
        self.tab_name: str = tab_name
        self.source_bucket: str = source_bucket
        self.source_path: str = source_path
        self.destination_bucket: str = destination_bucket
        self.destination_path: str = destination_path
        self.gcp_conn_id: str = gcp_conn_id

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
        for index, row in enumerate(workbook[self.tab_name].rows):
            if index == 0:
                writer.writerow(
                    [
                        cell.value if cell.value is not None else f"Unnamed: {column}"
                        for column, cell in enumerate(row)
                    ]
                )
            else:
                writer.writerow([cell.value for cell in row])
        csv_file.seek(0)
        return csv.DictReader(csv_file)

    def execute(self, context: Context) -> str:
        self.gcs_hook().upload(
            bucket_name=self.destination_name(),
            object_name=self.destination_path,
            data=JsonlFormatter(self.rows()).format(),
            mime_type="application/jsonl",
            gzip=True,
        )
        return {
            "type": self.type,
            "year": self.year,
            "destination_path": self.destination_path,
        }
