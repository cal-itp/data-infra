import json
import os
from typing import Sequence

from airflow.models import BaseOperator
from airflow.models.taskinstance import Context
from airflow.providers.google.cloud.hooks.gcs import GCSHook

# BigQuery -> Frictionless Table Schema types
# (https://specs.frictionlessdata.io/table-schema/)
FRICTIONLESS_TYPES = {
    "STRING": "string",
    "BYTES": "string",
    "INT64": "integer",
    "INTEGER": "integer",
    "FLOAT64": "number",
    "FLOAT": "number",
    "NUMERIC": "number",
    "BIGNUMERIC": "number",
    "BOOL": "boolean",
    "BOOLEAN": "boolean",
    "TIMESTAMP": "datetime",
    "DATETIME": "datetime",
    "DATE": "date",
    "TIME": "time",
    "GEOGRAPHY": "string",
}


class TIDESFrictionlessMetadataOperator(BaseOperator):
    """Writes a Frictionless datapackage.json next to an exported table.

    The machine-readable data dictionary for one published TIDES reference
    table (SAM 5160.1): field names and types from the dbt catalog.json,
    field and table descriptions from manifest.json -- so the column docs in
    _mart_tides_reference.yml are the single source of the dictionary. The
    package's resources are the actual exported data files under the table's
    bucket prefix.
    """

    template_fields: Sequence[str] = (
        "bucket_name",
        "manifest_object_name",
        "catalog_object_name",
        "model_name",
        "destination_bucket",
        "destination_path_prefix",
        "user_project",
        "gcp_conn_id",
    )

    def __init__(
        self,
        bucket_name: str,
        model_name: str,
        destination_bucket: str,
        destination_path_prefix: str,
        user_project: str,
        manifest_object_name: str = "manifest.json",
        catalog_object_name: str = "catalog.json",
        gcp_conn_id: str = "google_cloud_default",
        **kwargs,
    ):
        super().__init__(**kwargs)

        self._gcs_hook: GCSHook = None
        self.bucket_name = bucket_name
        self.model_name = model_name
        self.destination_bucket = destination_bucket
        self.destination_path_prefix = destination_path_prefix
        self.user_project = user_project
        self.manifest_object_name = manifest_object_name
        self.catalog_object_name = catalog_object_name
        self.gcp_conn_id = gcp_conn_id

    def gcs_hook(self) -> GCSHook:
        if self._gcs_hook is None:
            self._gcs_hook = GCSHook(gcp_conn_id=self.gcp_conn_id)
        return self._gcs_hook

    def destination_name(self) -> str:
        return self.destination_bucket.replace("gs://", "")

    def read_json(self, object_name: str) -> dict:
        return json.loads(
            self.gcs_hook().download(
                bucket_name=self.bucket_name.replace("gs://", ""),
                object_name=object_name,
            )
        )

    def node_key(self) -> str:
        return f"model.calitp_warehouse.{self.model_name}"

    def manifest_node(self) -> dict:
        return self.read_json(self.manifest_object_name)["nodes"][self.node_key()]

    def catalog_node(self) -> dict:
        return self.read_json(self.catalog_object_name)["nodes"][self.node_key()]

    def fields(self) -> list[dict]:
        manifest_columns = self.manifest_node().get("columns", {})
        catalog_columns = self.catalog_node().get("columns", {})
        fields = []
        for name, column in sorted(
            catalog_columns.items(), key=lambda item: item[1]["index"]
        ):
            field = {
                "name": name,
                "type": FRICTIONLESS_TYPES.get(column["type"].upper(), "any"),
            }
            description = manifest_columns.get(name, {}).get("description")
            if description:
                field["description"] = description
            fields.append(field)
        return fields

    def data_file_names(self) -> list[str]:
        client = self.gcs_hook().get_conn()
        bucket = client.bucket(self.destination_name(), user_project=self.user_project)
        return sorted(
            blob.name.removeprefix(self.destination_path_prefix)
            for blob in client.list_blobs(bucket, prefix=self.destination_path_prefix)
            if blob.name.rsplit(".", 1)[-1] in ("parquet", "csv")
        )

    def datapackage(self, file_names: list[str], fields: list[dict]) -> dict:
        return {
            "profile": "tabular-data-package",
            "name": self.model_name,
            "title": self.model_name,
            "description": self.manifest_node().get("description", ""),
            "licenses": [
                {
                    "name": "CC-BY-4.0",
                    "title": "Creative Commons Attribution 4.0",
                    "path": "https://creativecommons.org/licenses/by/4.0/",
                }
            ],
            "contributors": [
                {
                    "title": "Cal-ITP / Caltrans Data & Digital Services",
                    "email": "hello@calitp.org",
                    "role": "publisher",
                }
            ],
            "resources": [
                {
                    "name": file_name.replace(".", "-").lower(),
                    "path": file_name,
                    "format": file_name.rsplit(".", 1)[-1],
                    "schema": {"fields": fields},
                }
                for file_name in file_names
            ],
        }

    def execute(self, context: Context) -> dict:
        datapackage = self.datapackage(self.data_file_names(), self.fields())

        object_name = os.path.join(self.destination_path_prefix, "datapackage.json")
        self.gcs_hook().upload(
            bucket_name=self.destination_name(),
            object_name=object_name,
            data=json.dumps(datapackage, indent=2),
            mime_type="application/json",
            gzip=False,
            user_project=self.user_project,
        )

        return {"destination_path": object_name}
