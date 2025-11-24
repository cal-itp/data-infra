import json
from typing import Literal, Optional, Sequence

from pydantic.v1 import BaseModel, validator

from airflow.models import BaseOperator
from airflow.models.taskinstance import Context
from airflow.providers.google.cloud.hooks.gcs import GCSHook


# This is DDP-8
class DictionaryRow(BaseModel):
    system_name: str
    table_name: str
    field_name: str
    field_alias: None
    field_description: str
    field_description_authority: str
    confidential: Literal["N"]
    sensitive: Literal["N"]
    pii: Literal["N"]
    pci: Literal["N"]
    field_type: str
    field_length: int
    field_precision: Optional[int]
    units: Optional[str]
    domain_type: Literal["Unrepresented"]
    allowable_min_value: None
    allowable_max_value: None
    usage_notes: None

    # constr has to_upper in newer pydantic versions
    @validator("field_type", allow_reuse=True)
    def field_type_uppercase(cls, v):
        return v.upper()


class DBTManifestToDictionaryOperator(BaseOperator):
    template_fields: Sequence[str] = (
        "bucket_name",
        "object_name",
        "gcp_conn_id",
    )

    def __init__(
        self,
        bucket_name: str,
        object_name: str,
        gcp_conn_id: str = "google_cloud_default",
        **kwargs,
    ):
        super().__init__(**kwargs)

        self.bucket_name: str = bucket_name
        self.object_name: str = object_name
        self.gcp_conn_id: str = gcp_conn_id
        self._manifest: dict = None

    def gcs_hook(self) -> GCSHook:
        return GCSHook(gcp_conn_id=self.gcp_conn_id)

    def manifest(self) -> dict[str, str | dict | list]:
        if not self._manifest:
            result = self.gcs_hook().download(
                bucket_name=self.bucket_name.replace("gs://", ""),
                object_name=self.object_name,
            )
            self._manifest = json.loads(result)
        return self._manifest

    def rows(self) -> list[dict]:
        exposure = (
            self.manifest()
            .get("exposures", {})
            .get("exposure.calitp_warehouse.california_open_data", {})
        )
        destinations = exposure.get("meta", {}).get("destinations", {})
        depends_on_nodes = exposure.get("depends_on", {}).get("nodes", [])
        depends_on_names = [node_name.split(".")[-1] for node_name in depends_on_nodes]
        result: list[DictionaryRow] = []
        for destination in destinations:
            for resource_name, resource in destination.get("resources", {}).items():
                if resource_name in depends_on_names:
                    node = self.manifest().get("nodes", {})[
                        f"model.calitp_warehouse.{resource_name}"
                    ]
                    for column_name, column in node["columns"].items():
                        if column.get("meta", {}).get("publish.include", False):
                            row = DictionaryRow(
                                system_name="Cal-ITP GTFS-Ingest Pipeline",
                                table_name=node["name"]
                                .replace("dim_", "")
                                .replace("_latest", ""),
                                field_name=column_name,
                                field_alias=None,
                                field_description=column["description"],
                                field_description_authority=column["meta"].get(
                                    "ckan.authority", node["meta"].get("ckan.authority")
                                ),
                                confidential="N",
                                sensitive="N",
                                pii="N",
                                pci="N",
                                field_type=column["meta"].get("ckan.type", "STRING"),
                                field_length=column["meta"].get("ckan.length", 1024),
                                field_precision=column["meta"].get("ckan.precision"),
                                units=column["meta"].get("ckan.units"),
                                domain_type="Unrepresented",
                                allowable_min_value=None,
                                allowable_max_value=None,
                                usage_notes=None,
                            )
                            result.append(
                                {
                                    k.upper(): v
                                    for k, v in json.loads(
                                        row.json(models_as_dict=False)
                                    ).items()
                                }
                            )

        return result

    def execute(self, context: Context) -> str:
        return self.rows()
