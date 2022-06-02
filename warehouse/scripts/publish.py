"""
Publishes various dbt models to various sources.
"""
from datetime import timedelta

import csv

import pendulum
from typing import Optional, Literal, List

from pathlib import Path

import subprocess

import enum

import json
import os
import shapely.geometry
import shapely.wkt
import tempfile

import gcsfs
import geopandas as gpd
import humanize
import pandas as pd
import requests
import swifter  # noqa
import typer
from pydantic import BaseModel

from dbt_artifacts import (
    BaseNode,
    CkanDestination,
    Exposure,
    Manifest,
    TileServerDestination,
)
from tqdm import tqdm

tqdm.pandas()

API_KEY = os.environ.get("CALITP_CKAN_GTFS_SCHEDULE_KEY")

app = typer.Typer()

WGS84 = "EPSG:4326"


def _publish_exposure(
    project: str, bucket: str, exposure: Exposure, dry_run: bool, deploy: bool
):
    for destination in exposure.meta.destinations:
        with tempfile.TemporaryDirectory() as tmpdir:
            if isinstance(destination, CkanDestination):
                if len(exposure.depends_on.nodes) != len(destination.ids):
                    typer.secho(
                        f"WARNING: mismatch between {len(exposure.depends_on.nodes)} depends_on nodes and {len(destination.ids)} destination ids",
                        fg=typer.colors.YELLOW,
                    )

                # TODO: this should probably be driven by the depends_on nodes
                for model_name, ckan_id in destination.ids.items():
                    typer.secho(f"handling {model_name} {ckan_id}")
                    node = BaseNode._instances[f"model.calitp_warehouse.{model_name}"]

                    fpath = os.path.join(tmpdir, destination.filename(model_name))

                    df = pd.read_gbq(
                        str(node.select),
                        project_id=node.database,
                        progress_bar_type="tqdm",
                    )
                    df.to_csv(fpath, index=False)
                    typer.secho(
                        f"selected {len(df)} rows ({humanize.naturalsize(os.stat(fpath).st_size)}) from {node.schema_table}"
                    )

                    hive_path = destination.hive_path(exposure, model_name, bucket)

                    write_msg = f"writing {model_name} to {hive_path}"
                    upload_msg = f"uploading to {destination.url} {ckan_id}"
                    if dry_run:
                        typer.secho(
                            f"would be {write_msg} and {upload_msg}",
                            fg=typer.colors.MAGENTA,
                        )
                    else:
                        typer.secho(write_msg, fg=typer.colors.GREEN)
                        fs = gcsfs.GCSFileSystem(token="google_default")
                        fs.put(fpath, hive_path)

                        if deploy:
                            typer.secho(upload_msg, fg=typer.colors.GREEN)
                            with open(fpath, "rb") as fp:
                                requests.post(
                                    destination.url,
                                    data={"id": ckan_id},
                                    headers={"Authorization": API_KEY},
                                    files={"upload": fp},
                                ).raise_for_status()

            elif isinstance(destination, TileServerDestination):
                # the depends_on each create a layer
                for model in exposure.depends_on.nodes:
                    node = BaseNode._instances[model]

                    geojson_fpath = os.path.join(tmpdir, f"{node.name}.geojson")
                    fpath = os.path.join(tmpdir, destination.filename(node.name))

                    df = pd.read_gbq(
                        str(node.select),
                        project_id=project,
                        progress_bar_type="tqdm",
                    )
                    # typer.secho(
                    #     f"selected {len(df)} rows ({humanize.naturalsize(os.stat(fpath).st_size)}) from {model_name}"
                    # )

                    def make_linestring(x):
                        """
                        This comes from https://github.com/cal-itp/data-analyses/blob/09f3b23c488e7ed1708ba721bf49121a925a8e0b/_shared_utils/shared_utils/geography_utils.py#L190

                        It's specific to dim_shapes_geo, so we should update this when we actually start producing geojson
                        """
                        # shapely errors if the array contains only one point
                        if len(x) > 1:
                            # each point in the array is wkt
                            # so convert them to shapely points via list comprehension
                            as_wkt = [shapely.wkt.loads(i) for i in x]
                            return shapely.geometry.LineString(as_wkt)

                    # apply the function
                    df["geometry"] = df.pt_array.swifter.apply(make_linestring)
                    gdf = gpd.GeoDataFrame(df, geometry="geometry", crs=WGS84)
                    # gdf = gdf.to_crs(WGS84)
                    gdf[["geometry"]].to_file(geojson_fpath, driver="GeoJSON")

                    args = [
                        "tippecanoe",
                        "-zg",
                        "-o",
                        fpath,
                        geojson_fpath,
                    ]
                    typer.secho(f"running tippecanoe with args {args}")
                    subprocess.run(args).check_returncode()

                    hive_path = destination.hive_path(exposure, node.name, bucket)

                    if dry_run:
                        typer.secho(
                            f"would be writing {model_name} to {hive_path} and {destination.url} {ckan_id}",
                            fg=typer.colors.MAGENTA,
                        )
                    else:
                        fs = gcsfs.GCSFileSystem(token="google_default")
                        fs.put(fpath, hive_path)


with open("./target/manifest.json") as f:
    ExistingExposure = enum.Enum(
        "ExistingExposure",
        {
            exposure.name: exposure.name
            for exposure in Manifest(**json.load(f)).exposures.values()
        },
    )


# once https://github.com/samuelcolvin/pydantic/pull/2745 is merged, we don't need this
class ListOfStrings(BaseModel):
    __root__: List[str]


class MetadataRow(BaseModel):
    dataset_name: str
    tags: ListOfStrings
    description: str
    methodology: str
    topic: Literal["Transportation"]
    publisher_organization: Literal["Caltrans"]
    place: Literal["CA"]
    frequency: str
    next_update: pendulum.Date
    creation_date: pendulum.Date
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
    data_standard: Literal["https://developers.google.com/transit/gtfs"]
    notes: None
    gis_theme: None
    gis_horiz_accuracy: None
    gis_vert_accuracy: None
    gis_coordinate_system_epsg: Optional[str]
    gis_vert_datum_epsg: None

    class Config:
        json_encoders = {
            ListOfStrings: lambda los: ",".join(los.__root__),
        }


class YesOrNo(str, enum.Enum):
    y = "Y"
    n = "N"


class DictionaryRow(BaseModel):
    system_name: str
    table_name: str
    field_name: str
    field_alias: None
    field_description: str
    field_description_authority: Optional[str]
    confidential: Literal["N"]
    sensitive: Literal["N"]
    pii: Literal["N"]
    pci: Literal["N"]
    field_type: str
    field_length: int
    field_precision: None
    units: None
    domain_type: Literal["Unrepresented"]
    allowable_min_value: None
    allowable_max_value: None
    usage_notes: None


@app.command()
def generate_exposure_documentation(
    exposure: ExistingExposure,
    metadata_output: Path = "./metadata.csv",
    dictionary_output: Path = "./dictionary.csv",
) -> None:
    with open("./target/manifest.json") as f:
        manifest = Manifest(**json.load(f))

    exposure = manifest.exposures[f"exposure.calitp_warehouse.{exposure.value}"]

    with open(metadata_output, "w", newline="") as mf, open(
        dictionary_output, "w", newline=""
    ) as df:
        writer = csv.DictWriter(mf, fieldnames=MetadataRow.__fields__.keys())
        writer.writeheader()

        dictionary_writer = csv.DictWriter(
            df, fieldnames=DictionaryRow.__fields__.keys()
        )
        dictionary_writer.writeheader()

        for node in exposure.depends_on.resolved_nodes:
            writer.writerow(
                json.loads(
                    MetadataRow(
                        dataset_name=node.name,
                        tags=[
                            "transit",
                            "gtfs",
                            "gtfs-schedule",
                            "bus",
                            "rail",
                            "ferry",
                            "mobility",
                        ],
                        description=node.description.replace("\n", " "),
                        methodology=exposure.meta.methodology,
                        topic="Transportation",
                        publisher_organization="Caltrans",
                        place="CA",
                        frequency="Monthly",
                        next_update=pendulum.today() + timedelta(days=30),
                        creation_date=pendulum.today(),
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
                        data_standard="https://developers.google.com/transit/gtfs",
                        notes=None,
                        gis_theme=None,
                        gis_horiz_accuracy=None,
                        gis_vert_accuracy=None,
                        gis_coordinate_system_epsg=node.meta.get(
                            "publish.gis_coordinate_system_epsg"
                        ),
                        gis_vert_datum_epsg=None,
                    ).json(models_as_dict=False)
                )
            )

            for name, column in node.columns.items():
                dictionary_writer.writerow(
                    json.loads(
                        DictionaryRow(
                            system_name="Cal-ITP GTFS-Ingest Pipeline",
                            table_name=node.name,
                            field_name=column.name,
                            field_alias=None,
                            field_description=column.description,
                            field_description_authority="",
                            confidential="N",
                            sensitive="N",
                            pii="N",
                            pci="N",
                            field_type=column.meta.get("publish.type", "STRING"),
                            field_length=column.meta.get("publish.length", 1024),
                            field_precision=None,
                            units=None,
                            domain_type="Unrepresented",
                            allowable_min_value=None,
                            allowable_max_value=None,
                            usage_notes=None,
                        ).json()
                    )
                )


@app.command()
def publish_exposure(
    exposure: ExistingExposure,
    project: str = typer.Option("cal-itp-data-infra-staging"),
    bucket: str = typer.Option(
        "gs://test-calitp-publish", help="The bucket in which artifacts are persisted."
    ),
    dry_run: bool = typer.Option(False, help="If True, skips writing out any data."),
    deploy: bool = typer.Option(
        False, help="If True, actually deploy to external systems."
    ),
) -> None:
    """
    Only publish one exposure, by name.
    """
    if deploy:
        assert not dry_run, "cannot deploy during a dry run!"
        assert not project.endswith(
            "-staging"
        ), "cannot deploy from the staging project!"
        assert not bucket.startswith("gs://test-"), "cannot deploy with a test bucket!"

    with open("./target/manifest.json") as f:
        manifest = Manifest(**json.load(f))

    exposure = manifest.exposures[f"exposure.calitp_warehouse.{exposure.value}"]

    _publish_exposure(
        project=project,
        bucket=bucket,
        exposure=exposure,
        dry_run=dry_run,
        deploy=deploy,
    )


if __name__ == "__main__":
    app()
