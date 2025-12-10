import json
from typing import Sequence

import pendulum
from google.cloud.bigquery.table import Row

from airflow.models import BaseOperator, DagRun
from airflow.models.taskinstance import Context
from airflow.providers.google.cloud.hooks.bigquery import BigQueryHook
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class DownloadConfigRow:
    row: dict

    def __init__(self, row: Row):
        self.row = dict(row)

    def query(self):
        result = {}
        if self.row["authorization_url_parameter_name"] is not None:
            result[self.row["authorization_url_parameter_name"]] = self.row[
                "url_secret_key_name"
            ]
        return result

    def headers(self):
        result = {}
        if self.row["authorization_header_parameter_name"] is not None:
            result[self.row["authorization_header_parameter_name"]] = self.row[
                "header_secret_key_name"
            ]
        return result

    def resolve(
        self, current_time: pendulum.DateTime, mapped_rows: dict[str, Row]
    ) -> dict:
        schedule_url_for_validation = None
        if (
            self.row["schedule_to_use_for_rt_validation_gtfs_dataset_key"]
            in mapped_rows
        ):
            schedule_url_for_validation = mapped_rows[
                self.row["schedule_to_use_for_rt_validation_gtfs_dataset_key"]
            ]["uri"]
        return {
            "extracted_at": current_time.isoformat(),
            "name": self.row["name"],
            "url": self.row["pipeline_url"],
            "feed_type": self.row["type"],
            "schedule_url_for_validation": schedule_url_for_validation,
            "auth_query_params": self.query(),
            "auth_headers": self.headers(),
            "computed": False,
        }


class ActiveRowQuery:
    def __init__(self, rows: list[dict], current_time: pendulum.DateTime):
        self.rows = rows
        self.current_time = current_time

    def resolve(self) -> list[dict]:
        resolved = []
        for row in self.rows:
            if (
                row["_is_current"]
                and row["data_quality_pipeline"]
                and row["deprecated_date"] is None
            ):
                resolved.append(row)
        return resolved


class BigQueryToDownloadConfigOperator(BaseOperator):
    template_fields: Sequence[str] = (
        "dataset_name",
        "table_name",
        "destination_bucket",
        "destination_path",
        "gcp_conn_id",
    )

    def __init__(
        self,
        dataset_name: str,
        table_name: str,
        destination_bucket: str,
        destination_path: str,
        gcp_conn_id: str = "google_cloud_default",
        **kwargs,
    ) -> None:
        super().__init__(**kwargs)

        self._gcs_hook = None
        self._big_query_hook = None
        self.dataset_name = dataset_name
        self.table_name = table_name
        self.destination_bucket = destination_bucket
        self.destination_path = destination_path
        self.gcp_conn_id = gcp_conn_id

    def destination_name(self) -> str:
        return self.destination_bucket.replace("gs://", "")

    def gcs_hook(self) -> GCSHook:
        return GCSHook(gcp_conn_id=self.gcp_conn_id)

    def bigquery_hook(self) -> BigQueryHook:
        return BigQueryHook(gcp_conn_id=self.gcp_conn_id)

    def download_config_rows(self, current_time: pendulum.DateTime) -> list:
        response = self.bigquery_hook().list_rows(
            dataset_id=self.dataset_name, table_id=self.table_name
        )
        active_rows = ActiveRowQuery(
            rows=list(response), current_time=current_time
        ).resolve()
        mapped_rows = {row["key"]: row for row in active_rows}
        return [
            DownloadConfigRow(row).resolve(current_time, mapped_rows)
            for row in active_rows
        ]

    def metadata(self, current_time: pendulum.DateTime) -> dict:
        return {
            "PARTITIONED_ARTIFACT_METADATA": json.dumps(
                {
                    "filename": "configs.jsonl.gz",
                    "ts": current_time.isoformat(),
                }
            )
        }

    def execute(self, context: Context) -> str:
        dag_run: DagRun = context["dag_run"]
        logical_date: pendulum.DateTime = pendulum.instance(dag_run.logical_date)
        rows = self.download_config_rows(current_time=logical_date)
        self.gcs_hook().upload(
            bucket_name=self.destination_name(),
            object_name=self.destination_path,
            data="\n".join([json.dumps(r, separators=(",", ":")) for r in rows]),
            mime_type="application/jsonl",
            gzip=True,
            metadata=self.metadata(current_time=logical_date),
        )
        return [{"destination_path": self.destination_path}]
