import os
from typing import Sequence

from airflow.models import BaseOperator
from airflow.models.taskinstance import Context
from airflow.providers.google.cloud.hooks.bigquery import BigQueryHook


class TidesMetadataSidecarOperator(BaseOperator):
    template_fields: Sequence[str] = (
        "destination_bucket_name",
        "destination_object_name",
        "warehouse_dataset",
        "gcp_conn_id",
    )

    def __init__(
        self,
        destination_bucket_name: str,
        destination_object_name: str,
        warehouse_dataset: str = "mart_transit_database",
        gcp_conn_id: str = "google_cloud_default",
        location: str = os.getenv("CALITP_BQ_LOCATION"),
        **kwargs,
    ):
        super().__init__(**kwargs)

        self.destination_bucket_name = destination_bucket_name
        self.destination_object_name = destination_object_name
        self.warehouse_dataset = warehouse_dataset
        self.gcp_conn_id = gcp_conn_id
        self.location = location

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
            "format='JSON',"
            "overwrite=true"
            ") AS "
            "SELECT DISTINCT gtfs_dataset_key, organization_name, organization_ntd_id "
            "FROM {dataset}.dim_provider_gtfs_data "
            "WHERE public_customer_facing_or_regional_subfeed_fixed_route = TRUE "
            "AND gtfs_dataset_key IS NOT NULL "
            "ORDER BY gtfs_dataset_key"
        )
        return template.format(uri=self.destination(), dataset=self.warehouse_dataset)

    def execute(self, context: Context) -> str:
        self.bigquery_hook().get_client().query_and_wait(query=self.query())
        return self.destination()
