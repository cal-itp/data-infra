import csv
import io
import json
import os
from typing import Sequence

from airflow.models import BaseOperator
from airflow.models.taskinstance import Context
from airflow.providers.google.cloud.hooks.bigquery import BigQueryHook
from airflow.providers.google.cloud.hooks.gcs import GCSHook


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
        location: str = os.getenv("CALITP_BQ_LOCATION"),
        **kwargs,
    ):
        super().__init__(**kwargs)

        self.source_bucket_name: str = source_bucket_name
        self.source_object_name: str = source_object_name
        self.destination_bucket_name: str = destination_bucket_name
        self.destination_object_name: str = destination_object_name
        self.table_name: str = table_name
        self.gcp_conn_id: str = gcp_conn_id
        self.location: str = location
        self._manifest: dict = None

    def gcs_hook(self) -> GCSHook:
        return GCSHook(gcp_conn_id=self.gcp_conn_id)

    def bigquery_hook(self) -> BigQueryHook:
        return BigQueryHook(
            gcp_conn_id=self.gcp_conn_id,
            location=self.location,
            use_legacy_sql=False,
        )

    def manifest(self) -> dict[str, str | dict | list]:
        if not self._manifest:
            result = self.gcs_hook().download(
                bucket_name=self.source_bucket_name.replace("gs://", ""),
                object_name=self.source_object_name,
            )
            self._manifest = json.loads(result)
        return self._manifest

    def node(self) -> str:
        exposure = (
            self.manifest()
            .get("exposures", {})
            .get("exposure.calitp_warehouse.california_open_data", {})
        )
        destinations = exposure.get("meta", {}).get("destinations", {})
        depends_on_nodes = exposure.get("depends_on", {}).get("nodes", [])
        depends_on_names = [node_name.split(".")[-1] for node_name in depends_on_nodes]
        for destination in destinations:
            for resource_name, resource in destination.get("resources", {}).items():
                if (
                    resource_name in depends_on_names
                    and resource_name.removeprefix("dim_").removesuffix("_latest")
                    == self.table_name
                ):
                    return self.manifest().get("nodes", {})[
                        f"model.calitp_warehouse.{resource_name}"
                    ]

    def dataset_id(self) -> str:
        return self.node()["schema"]

    def table_id(self) -> str:
        return self.node()["name"]

    def column_names(self) -> list[str]:
        return [
            name
            for name, column in self.node()["columns"].items()
            if column.get("meta", {}).get("publish.include", False)
        ]

    def csv(self) -> str:
        items = self.bigquery_hook().get_records(
            f"SELECT {','.join(self.column_names())} FROM {self.dataset_id()}.{self.table_id()}",
        )
        output = io.StringIO()
        writer = csv.DictWriter(output, fieldnames=self.column_names(), delimiter="\t")
        writer.writeheader()
        writer.writerows([dict(zip(self.column_names(), item)) for item in items])
        return output.getvalue()

    def execute(self, context: Context) -> str:
        self.gcs_hook().upload(
            bucket_name=self.destination_bucket_name.replace("gs://", ""),
            object_name=context["task"].render_template(
                self.destination_object_name, context
            ),
            data=self.csv(),
            mime_type="text/csv",
        )
        return os.path.join(self.destination_bucket_name, self.destination_object_name)
