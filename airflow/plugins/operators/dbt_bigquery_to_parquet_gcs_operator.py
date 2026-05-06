import os
from typing import Sequence

from airflow.models import BaseOperator
from airflow.models.taskinstance import Context
from airflow.providers.google.cloud.hooks.bigquery import BigQueryHook


class DBTBigQueryToParquetGCSOperator(BaseOperator):
    template_fields: Sequence[str] = (
        "destination_bucket_name",
        "destination_object_name",
        "dataset_id",
        "table_name",
        "gcp_conn_id",
    )

    def __init__(
        self,
        destination_bucket_name: str,
        destination_object_name: str,
        dataset_id: str,
        table_name: str,
        gcp_conn_id: str = "google_cloud_default",
        location: str = os.getenv("CALITP_BQ_LOCATION"),
        **kwargs,
    ):
        super().__init__(**kwargs)

        self.destination_bucket_name: str = destination_bucket_name
        self.destination_object_name: str = destination_object_name
        self.dataset_id: str = dataset_id
        self.table_name: str = table_name
        self.gcp_conn_id: str = gcp_conn_id
        self.location: str = location

    def bigquery_hook(self) -> BigQueryHook:
        return BigQueryHook(
            gcp_conn_id=self.gcp_conn_id,
            location=self.location,
        )

    def destination(self) -> str:
        return os.path.join(self.destination_bucket_name, self.destination_object_name)

    def query(self) -> str:
        template = (
            "EXPORT DATA OPTIONS("
            "uri='{uri}',"
            "format='PARQUET',"
            "compression='SNAPPY',"
            "overwrite=true"
            ") AS SELECT * FROM {dataset}.{table}"
        )
        return template.format(
            uri=self.destination(),
            dataset=self.dataset_id,
            table=self.table_name,
        )

    def execute(self, context: Context) -> dict:
        self.bigquery_hook().get_client().query_and_wait(query=self.query())
        return {
            "destination_path_prefix": os.path.dirname(self.destination()),
        }
