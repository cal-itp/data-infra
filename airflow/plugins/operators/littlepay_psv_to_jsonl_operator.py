import csv
import io
import json
from typing import Sequence

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


class LittlepayPSVToJSONLOperator(BaseOperator):
    template_fields: Sequence[str] = (
        "source_bucket",
        "source_path",
        "destination_bucket",
        "destination_path",
        "gcp_conn_id",
    )

    def __init__(
        self,
        source_bucket: str,
        source_path: str,
        destination_bucket: str,
        destination_path: str,
        gcp_conn_id: str = "google_cloud_default",
        **kwargs,
    ) -> None:
        super().__init__(**kwargs)

        self._gcs_hook = None
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
        reader = csv.DictReader(
            io.StringIO(self.source().decode("utf-8-sig")),
            restkey="calitp_unknown_fields",
            delimiter="|",
        )
        return [
            {**row, "_line_number": line_number}
            for line_number, row in enumerate(reader, start=1)
        ]

    def execute(self, context: Context) -> str:
        self.gcs_hook().upload(
            bucket_name=self.destination_name(),
            object_name=self.destination_path,
            data=JsonlFormatter(self.rows()).format(),
            mime_type="application/jsonl",
            gzip=True,
        )

        return {
            "destination_path": self.destination_path,
        }
