import json
import os
from datetime import datetime
from typing import Sequence

from hooks.airtable_hook import AirtableHook
from src.bigquery_cleaner import BigQueryKeyCleaner, BigQueryValueCleaner

from airflow.models import BaseOperator, DagRun
from airflow.models.taskinstance import Context
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class AirtableObjectPath:
    air_base_name: str
    air_table_name: str

    def __init__(self, air_base_name: str, air_table_name: str) -> None:
        self.air_base_name = air_base_name
        self.air_table_name = air_table_name

    def safe_air_table_name(self) -> str:
        result = str.lower("_".join(self.air_table_name.split(" ")))
        result = result.replace("-", "_")
        result = result.replace("+", "and")
        return result

    def resolve(self, logical_date: datetime) -> str:
        return os.path.join(
            f"{self.air_base_name}__{self.safe_air_table_name()}",
            f"dt={logical_date.date().isoformat()}",
            f"ts={logical_date.isoformat()}",
            f"{self.safe_air_table_name()}.jsonl.gz",
        )


class AirtableCleaner:
    rows: list

    def __init__(self, rows: list):
        self.rows = rows

    def clean(self) -> list:
        result = []
        for row in self.rows:
            fields = {
                BigQueryKeyCleaner(k).clean(): BigQueryValueCleaner(v).clean()
                for k, v in row["fields"].items()
            }
            result.append({"id": row["id"], **fields})
        return result


class AirtableToGCSOperator(BaseOperator):
    _gcs_hook: GCSHook
    _airtable_hook: AirtableHook
    template_fields: Sequence[str] = (
        "air_base_id",
        "air_base_name",
        "air_table_name",
        "bucket",
        "airtable_conn_id",
        "gcp_conn_id",
    )

    def __init__(
        self,
        air_base_id: str,
        air_base_name: str,
        air_table_name: str,
        bucket: str,
        airtable_conn_id: str = "airtable_default",
        gcp_conn_id: str = "google_cloud_default",
        **kwargs,
    ) -> None:
        super().__init__(**kwargs)

        self._gcs_hook = None
        self._airtable_hook = None
        self.air_base_id = air_base_id
        self.air_base_name = air_base_name
        self.air_table_name = air_table_name
        self.bucket = bucket
        self.airtable_conn_id = airtable_conn_id
        self.gcp_conn_id = gcp_conn_id

    def bucket_name(self) -> str:
        return self.bucket.replace("gs://", "")

    def object_path(self) -> AirtableObjectPath:
        return AirtableObjectPath(self.air_base_name, self.air_table_name)

    def gcs_hook(self) -> GCSHook:
        return GCSHook(gcp_conn_id=self.gcp_conn_id)

    def airtable_hook(self) -> AirtableHook:
        return AirtableHook(airtable_conn_id=self.airtable_conn_id)

    def cleaned_airtable_rows(self) -> list:
        result = self.airtable_hook().read(self.air_base_id, self.air_table_name)
        return [
            json.dumps(x, separators=(",", ":"))
            for x in AirtableCleaner(result).clean()
        ]

    def execute(self, context: Context) -> str:
        dag_run: DagRun = context["dag_run"]
        object_name: str = self.object_path().resolve(dag_run.logical_date)
        self.gcs_hook().upload(
            bucket_name=self.bucket_name(),
            object_name=object_name,
            data="\n".join(self.cleaned_airtable_rows()),
            mime_type="application/jsonl",
            gzip=True,
        )
        return os.path.join(self.bucket, object_name)
