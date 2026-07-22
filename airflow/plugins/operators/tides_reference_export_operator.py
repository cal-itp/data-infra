import json
import os
from typing import Sequence

from airflow.models import BaseOperator
from airflow.models.taskinstance import Context
from airflow.providers.google.cloud.hooks.bigquery import BigQueryHook
from airflow.providers.google.cloud.hooks.gcs import GCSHook


def reference_destination_prefix(model_name: str, dt: str) -> str:
    """The bucket prefix a reference model is exported to.

    *_latest models live at a stable path that is overwritten each run;
    history models are stamped per run date (pass a template like
    "{{ ds }}", or "*" to build a matching pattern).
    """
    if model_name.endswith("_latest"):
        return os.path.join("reference", model_name) + "/"
    return os.path.join("reference", model_name, f"dt={dt}") + "/"


class TIDESReferenceExportOperator(BaseOperator):
    """Exports one whole reference table to the TIDES bucket, parquet + CSV.

    Sibling of TIDESBigQueryToParquetOperator, minus the per-feed-day filter:
    reference tables (the tides_reference dbt models) are small crosswalk /
    naming dims exported in full. Writes a JSONL outcome report alongside,
    mirroring the fact exports.
    """

    template_fields: Sequence[str] = (
        "ts",
        "dataset_name",
        "table_name",
        "destination_bucket",
        "destination_path_prefix",
        "report_path",
        "user_project",
        "gcp_conn_id",
    )

    def __init__(
        self,
        ts: str,
        dataset_name: str,
        table_name: str,
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
        self.ts: str = ts
        self.dataset_name: str = dataset_name
        self.table_name: str = table_name
        self.destination_bucket: str = destination_bucket
        self.destination_path_prefix: str = destination_path_prefix
        self.report_path: str = report_path
        self.user_project: str = user_project
        self.gcp_conn_id: str = gcp_conn_id

    def location(self) -> str:
        return os.getenv("CALITP_BQ_LOCATION")

    def destination_name(self) -> str:
        return self.destination_bucket.replace("gs://", "")

    def destination_path(self, extension: str) -> str:
        return os.path.join(
            self.destination_path_prefix,
            f"data_*.{extension}",
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
            "destination_parquet_path": self.destination_path("parquet"),
            "destination_csv_path": self.destination_path("csv"),
            "ts": self.ts,
        }

    def queries(self) -> list[str]:
        parquet_template = """
            EXPORT DATA OPTIONS(
            uri='{uri}',
            format='PARQUET',
            compression='SNAPPY',
            overwrite=true
            ) AS SELECT * FROM `{dataset}.{table}`
        """
        csv_template = """
            EXPORT DATA OPTIONS(
            uri='{uri}',
            format='CSV',
            header=true,
            overwrite=true
            ) AS SELECT * FROM `{dataset}.{table}`
        """
        return [
            template.format(
                uri=os.path.join(
                    self.destination_bucket,
                    self.destination_path(extension),
                ),
                dataset=self.dataset_name,
                table=self.table_name,
            )
            for template, extension in (
                (parquet_template, "parquet"),
                (csv_template, "csv"),
            )
        ]

    def execute(self, context: Context) -> dict:
        for query in self.queries():
            self.bigquery_hook().get_client().query_and_wait(query=query)

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

        return self.report_metadata()
