import json
import os
from typing import Sequence

from airflow.models import BaseOperator
from airflow.models.taskinstance import Context
from airflow.providers.google.cloud.hooks.bigquery import BigQueryHook
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class DBTBigQueryToParquetGCSOperator(BaseOperator):
    template_fields: Sequence[str] = (
        "source_bucket_name",
        "source_object_name",
        "destination_bucket_name",
        "destination_object_name",
        "table_name",
        "exposure_name",
        "gcp_conn_id",
    )

    def __init__(
        self,
        source_bucket_name: str,
        source_object_name: str,
        destination_bucket_name: str,
        destination_object_name: str,
        table_name: str,
        exposure_name: str,
        gcp_conn_id: str = "google_cloud_default",
        location: str = os.getenv("CALITP_BQ_LOCATION"),
        **kwargs,
    ):
        super().__init__(**kwargs)

        self.source_bucket_name: str = source_bucket_name
        self.source_object_name: str = source_object_name
        self.destination_bucket_name: str = destination_bucket_name
        self.destination_object_name: str = destination_object_name
        self.table_name: str = table_name
        self.exposure_name: str = exposure_name
        self.gcp_conn_id: str = gcp_conn_id
        self.location: str = location
        self._manifest: dict = None

    def gcs_hook(self) -> GCSHook:
        return GCSHook(gcp_conn_id=self.gcp_conn_id)

    def bigquery_hook(self) -> BigQueryHook:
        return BigQueryHook(
            gcp_conn_id=self.gcp_conn_id,
            location=self.location,
        )

    def manifest(self) -> dict[str, str | dict | list]:
        if not self._manifest:
            result = self.gcs_hook().download(
                bucket_name=self.source_bucket_name.replace("gs://", ""),
                object_name=self.source_object_name,
            )
            self._manifest = json.loads(result)
        return self._manifest

    def node(self) -> dict:
        exposure = self.manifest().get("exposures", {}).get(self.exposure_name, {})
        depends_on_nodes = exposure.get("depends_on", {}).get("nodes", [])
        depends_on_names = [node_name.split(".")[-1] for node_name in depends_on_nodes]
        if self.table_name not in depends_on_names:
            return None
        return self.manifest().get("nodes", {})[
            f"model.calitp_warehouse.{self.table_name}"
        ]

    def dataset_id(self) -> str:
        return self.node()["schema"]

    def table_id(self) -> str:
        return self.node()["name"]

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
            dataset=self.dataset_id(),
            table=self.table_id(),
        )

    def execute(self, context: Context) -> dict:
        self.bigquery_hook().get_client().query_and_wait(query=self.query())
        return {
            "destination_path_prefix": os.path.dirname(self.destination()),
        }
