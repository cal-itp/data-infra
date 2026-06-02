import json
import os
from typing import Sequence

from airflow.models import BaseOperator
from airflow.models.taskinstance import Context
from airflow.providers.google.cloud.hooks.bigquery import BigQueryHook
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class TIDESBigQueryToParquetOperator(BaseOperator):
    template_fields: Sequence[str] = (
        "dt",
        "ts",
        "dataset_name",
        "table_name",
        "organization_source_record_id",
        "base64_url",
        "display_name",
        "destination_bucket",
        "destination_path_prefix",
        "report_path",
        "user_project",
        "gcp_conn_id",
    )

    def __init__(
        self,
        dt: str,
        ts: str,
        dataset_name: str,
        table_name: str,
        organization_source_record_id: str,
        base64_url: str,
        display_name: str,
        destination_bucket: str,
        destination_path_prefix: str,
        report_path: str,
        user_project: str,
        gcp_conn_id: str = "google_cloud_default",
        **kwargs,
    ):
        super().__init__(**kwargs)

        self._gcs_hook: GCSHook = None
        self._big_query_hook: BigQueryHook = None
        self.dt: str = dt
        self.ts: str = ts
        self.dataset_name: str = dataset_name
        self.table_name: str = table_name
        self.organization_source_record_id: str = organization_source_record_id
        self.base64_url: str = base64_url
        self.display_name: str = display_name
        self.destination_bucket: str = destination_bucket
        self.destination_path_prefix: str = destination_path_prefix
        self.report_path: str = report_path
        self.user_project: str = user_project
        self.gcp_conn_id: str = gcp_conn_id

    def location(self) -> str:
        return os.getenv("CALITP_BQ_LOCATION")

    def destination_name(self) -> str:
        return self.destination_bucket.replace("gs://", "")

    def destination_path(self) -> str:
        return os.path.join(
            self.destination_path_prefix,
            "data_*.parquet",
        )

    def gcs_hook(self) -> GCSHook:
        if self._gcs_hook is None:
            self._gcs_hook = GCSHook(gcp_conn_id=self.gcp_conn_id)
        return self._gcs_hook

    def bigquery_hook(self) -> BigQueryHook:
        if self._big_query_hook is None:
            self._big_query_hook = BigQueryHook(
                gcp_conn_id=self.gcp_conn_id,
                location=self.location(),
                use_legacy_sql=False,
            )
        return self._big_query_hook

    def report_metadata(self) -> dict:
        return {
            "dataset_name": self.dataset_name,
            "table_name": self.table_name,
            "organization_source_record_id": self.organization_source_record_id,
            "base64_url": self.base64_url,
            "display_name": self.display_name,
            "destination_path": self.destination_path(),
            "service_date": self.dt,
            "ts": self.ts,
        }

    def query(self) -> str:
        template = """
            EXPORT DATA OPTIONS(
            uri='{uri}',
            format='PARQUET',
            compression='SNAPPY',
            overwrite=true
            ) AS SELECT * FROM `{dataset}.{table}`
            WHERE service_date = CAST('{dt}' AS DATE)
            AND base64_url = '{base64_url}'
        """
        return template.format(
            uri=os.path.join(
                self.destination_bucket,
                self.destination_path(),
            ),
            dataset=self.dataset_name,
            table=self.table_name,
            dt=self.dt,
            base64_url=self.base64_url,
        )

    def execute(self, context: Context) -> dict:
        self.bigquery_hook().get_client().query_and_wait(query=self.query())

        self.gcs_hook().upload(
            bucket_name=self.destination_name(),
            object_name=self.report_path,
            data=json.dumps(
                self.report_metadata(),
                default=str,
            ),
            mime_type="application/jsonl",
            gzip=False,
            user_project=self.user_project,
        )

        return {
            "organization_source_record_id": self.organization_source_record_id,
            "base64_url": self.base64_url,
            "display_name": self.display_name,
            "destination_path": self.destination_path(),
            "service_date": self.dt,
            "ts": self.ts,
        }
