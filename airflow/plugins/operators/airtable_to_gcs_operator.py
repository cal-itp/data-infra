import json
import os
import re
from datetime import datetime
from typing import Any, Sequence

from hooks.airtable_hook import AirtableHook

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
            f"{self.air_table_name}.jsonl.gz",
        )


class AirtableValueCleaner:
    value: Any

    def __init__(self, value: Any):
        self.value = value

    def clean(self):
        """
        BigQuery doesn't allow arrays that contain null values --
        see: https://cloud.google.com/bigquery/docs/reference/standard-sql/data-types#array_nulls
        Therefore we need to manually replace None with falsy values according
        to the type of data in the array.
        """
        result = self.value
        if isinstance(result, dict):
            for k, v in result.items():
                result[k] = AirtableValueCleaner(v).clean()
        elif isinstance(result, list):
            types = set(type(entry) for entry in result if entry is not None)
            if not types:
                result = []
            elif types <= {int, float}:
                result = [x if x is not None else -1 for x in result]
            else:
                result = [x if x is not None else "" for x in result]
        return result


class AirtableKeyCleaner:
    key: Any

    def __init__(self, key: Any):
        self.key = key

    def clean(self) -> str:
        """Replace non-word characters.
        See: https://cloud.google.com/bigquery/docs/reference/standard-sql/lexical#identifiers.
        Add underscore if starts with a number.  Also sometimes excel has columns names that are
        all numbers, not even strings of numbers (ﾉﾟ0ﾟ)ﾉ~
        """
        if not isinstance(self.key, str):
            self.key = str(self.key)
        if self.key[:1].isdigit():
            self.key = "_" + self.key
        return str.lower(re.sub(r"[^\w]", "_", self.key))


class AirtableRowCleaner:
    row: dict

    def __init__(self, row: dict):
        self.row = row

    def clean(self) -> dict:
        columns = {}
        for key, value in self.row["fields"].items():
            value = AirtableValueCleaner(value)
            columns[AirtableKeyCleaner(key).clean()] = value.clean()
        return {"id": self.row["id"], **columns}


class AirtableCleaner:
    rows: list

    def __init__(self, rows: list):
        self.rows = rows

    def clean(self) -> list:
        return [AirtableRowCleaner(row).clean() for row in self.rows]


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
