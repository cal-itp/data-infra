import csv
import io
import os
from typing import Sequence

from airflow.models import BaseOperator
from airflow.models.taskinstance import Context
from airflow.providers.google.cloud.hooks.gcs import GCSHook
from airflow.providers.google.cloud.hooks.bigquery import BigQueryHook


class DBTBigQueryToGCSOperator(BaseOperator):
    template_fields: Sequence[str] = (
        "source_bucket_name",
        "source_object_name",
        "destination_bucket_name",
        "destination_object_name",
        "table_name",
        "gcp_conn_id",
    )

    def __init__(
        self,
        source_bucket_name: str,
        source_object_name: str,
        destination_bucket_name: str,
        destination_object_name: str,
        table_name: str,
        gcp_conn_id: str = "google_cloud_default",
        **kwargs,
    ):
        super().__init__(**kwargs)

        self.source_bucket_name = source_bucket_name
        self.source_object_name = source_object_name
        self.destination_bucket_name = destination_bucket_name
        self.destination_object_name = destination_object_name
        self.table_name = table_name
        self.gcp_conn_id = gcp_conn_id

    def gcs_hook(self) -> GCSHook:
        return GCSHook(gcp_conn_id=self.gcp_conn_id)

    def bigquery_hook(self) -> BigQueryHook:
        return BigQueryHook(gcp_conn_id=self.gcp_conn_id, location="us-west2", use_legacy_sql=False)

    def manifest(self) -> dict[str, str | dict | list]:
        if not self._manifest:
            result = self.gcs_hook().download(
                bucket_name=self.bucket_name.replace("gs://", ""),
                object_name=self.object_name,
            )
            self._manifest = json.loads(result)
        return self._manifest

    def dataset_id(self) -> str:
        return "mart_gtfs_schedule_latest"

    def table_id(self) -> str:
        return "dim_agency_latest"

    def csv(self) -> str:
        items = self.bigquery_hook().get_records(
            f"SELECT * FROM {self.dataset_id()}.{self.table_id()}"
        )
        output = io.StringIO()
        writer = csv.DictWriter(output, fieldnames=items[0].keys(), delimiter="\t")
        writer.writeheader()
        writer.writerows(items)
        return output.getvalue()

    def execute(self, context: Context) -> str:
        self.gcs_hook().upload(
            bucket_name=self.destination_bucket_name.replace("gs://", ""),
            object_name=self.destination_object_name,
            data=self.csv(),
            mime_type="text/csv",
        )
        return os.path.join(self.destination_bucket_name, self.destination_object_name)
