from datetime import datetime, timedelta
import io
import os
import json
import csv

from airflow.models import BaseOperator, DagRun
from airflow.models.taskinstance import Context
from airflow.providers.google.cloud.hooks.gcs import GCSHook

from typing import Literal, Optional, Sequence
from pydantic import BaseModel, constr

class ListOfStrings(BaseModel):
    __root__: list[str]

class MetadataRow(BaseModel):
    dataset_name: str
    tags: ListOfStrings
    description: str
    methodology: str
    topic: Literal["Transportation"]
    publisher_organization: Literal["Caltrans"]
    place: Literal["CA"]
    frequency: str
    next_update: datetime
    creation_date: datetime
    last_update: None
    status: Literal["Complete"]
    temporal_coverage_begin: None
    temporal_coverage_end: None
    data_dictionary: str
    data_dictionary_type: Literal["csv"]
    contact_organization: Literal["Caltrans"]
    contact_position: Literal["Cal-ITP"]
    contact_name: Literal["Hunter Owens"]
    contact_email: Literal["hunter.owens@dot.ca.gov"]
    public_access_level: Literal["Public"]
    access_constraints: None
    use_constraints: Literal["Creative Commons 4.0 Attribution"]
    data_life_span: None
    caltrans_link: None
    data_standard: Literal["https://gtfs.org/schedule/"]
    notes: None
    gis_theme: None
    gis_horiz_accuracy: Optional[Literal["4m"]]
    gis_vert_accuracy: Optional[Literal["4m"]]
    gis_coordinate_system_epsg: Optional[constr(regex=r"\d+")]  # type: ignore # noqa: F722
    gis_vert_datum_epsg: None

    class Config:
        json_encoders = {
            ListOfStrings: lambda los: ",".join(los.__root__),
        }


class DBTManifestToMetadataOperator(BaseOperator):
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

        self.bucket_name = bucket_name
        self.object_name = object_name
        self.gcp_conn_id = gcp_conn_id

    def gcs_hook(self) -> GCSHook:
        return GCSHook(gcp_conn_id=self.gcp_conn_id)

    def read_manifest(self) -> dict:
        manifest = self.gcs_hook().download(
            bucket_name=self.bucket_name.replace("gs://", ""),
            object_name=self.object_name
        )
        return json.loads(manifest)

    def metadata_items(self, logical_date: datetime) -> str:
        manifest = self.read_manifest()
        exposure = manifest.get("exposures", {}).get("exposure.calitp_warehouse.california_open_data", {})
        destinations = exposure.get("meta", {}).get("destinations", {})
        depends_on_nodes = [name.split(".")[-1] for name in exposure.get("depends_on", {}).get("nodes", [])]
        items: dict[str, dict] = {}
        for destination in destinations:
            for resource_name, resource in destination.get("resources", {}).items():
                if resource_name in depends_on_nodes:
                    metadata_row = MetadataRow(
                        dataset_name=resource_name.removeprefix('dim_').removesuffix("_latest"),
                        tags=[
                            "transit",
                            "gtfs",
                            "gtfs-schedule",
                            "bus",
                            "rail",
                            "ferry",
                            "mobility",
                        ],
                        description=resource.get("description").replace("\n", " "),
                        methodology=exposure.get("meta").get("methodology").replace("\n", " "),
                        topic="Transportation",
                        publisher_organization="Caltrans",
                        place="CA",
                        frequency="Monthly",
                        next_update=logical_date + timedelta(days=30),
                        creation_date=logical_date,
                        last_update=None,
                        status="Complete",
                        temporal_coverage_begin=None,
                        temporal_coverage_end=None,
                        data_dictionary="",
                        data_dictionary_type="csv",
                        contact_organization="Caltrans",
                        contact_position="Cal-ITP",
                        contact_name="Hunter Owens",
                        contact_email="hunter.owens@dot.ca.gov",
                        public_access_level="Public",
                        access_constraints=None,
                        use_constraints="Creative Commons 4.0 Attribution",
                        data_life_span=None,
                        caltrans_link=None,
                        data_standard="https://gtfs.org/schedule/",
                        notes=None,
                        gis_theme=None,
                        gis_horiz_accuracy="4m",
                        gis_vert_accuracy="4m",
                        gis_coordinate_system_epsg=exposure.get("meta").get("coordinate_system_epsg"),
                        gis_vert_datum_epsg=None,
                    )
                    items[resource.get("id")] = {
                        k.upper(): v
                        for k, v in json.loads(metadata_row.json(models_as_dict=False)).items()
                    }

        return items

    def execute(self, context: Context) -> str:
        dag_run: DagRun = context["dag_run"]
        return self.metadata_items(logical_date=dag_run.logical_date)
