"""
Publishes various dbt models to various sources.
"""
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
from sqlalchemy import create_engine

from scripts.dbt_artifacts import (
    CkanDestination,
    Exposure,
    Manifest,
    Node,
    TileServerDestination,
)
from tqdm import tqdm

tqdm.pandas()

API_KEY = os.environ.get("CALITP_CKAN_GTFS_SCHEDULE_KEY")

app = typer.Typer()

WGS84 = "EPSG:4326"


# Taken from the calitp repo which we can't install because of deps issue
def get_engine(project, max_bytes=None):
    max_bytes = 5_000_000_000 if max_bytes is None else max_bytes

    # Note that we should be able to add location as a uri parameter, but
    # it is not being picked up, so passing as a separate argument for now.
    return create_engine(
        f"bigquery://{project}/?maximum_bytes_billed={max_bytes}",
        location="us-west2",
        credentials_path=os.environ.get("BIGQUERY_KEYFILE_LOCATION"),
    )


def _publish_exposure(project: str, bucket: str, exposure: Exposure, dry_run: bool):
    engine = get_engine(project)

    for destination in exposure.meta.destinations:
        with tempfile.TemporaryDirectory() as tmpdir:
            if isinstance(destination, CkanDestination):
                assert len(exposure.depends_on.nodes) == len(destination.ids)

                # TODO: this should probably be driven by the depends_on nodes
                for model_name, ckan_id in destination.ids.items():
                    typer.secho(f"handling {model_name} {ckan_id}")
                    node = Node._instances[f"model.calitp_warehouse.{model_name}"]

                    fpath = os.path.join(tmpdir, destination.filename(model_name))

                    df = pd.read_gbq(
                        str(node.select(engine)),
                        project_id=project,
                        progress_bar_type="tqdm",
                    )
                    df.to_csv(fpath, index=False)
                    typer.secho(
                        f"selected {len(df)} rows ({humanize.naturalsize(os.stat(fpath).st_size)}) from {node.schema_table}"
                    )

                    hive_path = destination.hive_path(exposure, model_name, bucket)

                    msg = f"writing {model_name} to {hive_path} and {destination.url} {ckan_id}"
                    if dry_run:
                        typer.secho(
                            f"would be {msg}",
                            fg=typer.colors.MAGENTA,
                        )
                    else:
                        typer.secho(msg, fg=typer.colors.GREEN)
                        fs = gcsfs.GCSFileSystem(
                            project=project, token="google_default"
                        )
                        fs.put(fpath, hive_path)

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
                    node = Node._instances[model]

                    geojson_fpath = os.path.join(tmpdir, f"{node.name}.geojson")
                    fpath = os.path.join(tmpdir, destination.filename(node.name))

                    # from https://gist.github.com/drmalex07/5a54fc4f1db06a66679e
                    df = pd.read_gbq(
                        str(node.select(engine)),
                        project_id=project,
                        progress_bar_type="tqdm",
                    )
                    # typer.secho(
                    #     f"selected {len(df)} rows ({humanize.naturalsize(os.stat(fpath).st_size)}) from {model_name}"
                    # )

                    def make_linestring(x):

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

                    subprocess.run(
                        [
                            "tippecanoe",
                            "-zg",
                            "-o",
                            fpath,
                            geojson_fpath,
                        ]
                    ).check_returncode()

                    hive_path = destination.hive_path(destination, node.name, bucket)

                    if dry_run:
                        typer.secho(
                            f"would be writing {model_name} to {hive_path} and {destination.url} {ckan_id}",
                            fg=typer.colors.MAGENTA,
                        )
                    else:
                        fs = gcsfs.GCSFileSystem(
                            project=project, token="google_default"
                        )
                        fs.put(fpath, hive_path)


with open("./target/manifest.json") as f:
    ExistingExposure = enum.Enum(
        "ExistingExposure",
        {
            exposure.name: exposure.name
            for exposure in Manifest(**json.load(f)).exposures.values()
        },
    )


@app.command()
def publish_exposure(
    exposure: ExistingExposure,
    project: str = "cal-itp-data-infra",
    bucket: str = "gs://calitp-publish",
    dry_run: bool = False,
) -> None:
    """
    Only publish one exposure, by name.
    """
    with open("./target/manifest.json") as f:
        manifest = Manifest(**json.load(f))

    exposure = manifest.exposures[f"exposure.calitp_warehouse.{exposure.value}"]

    _publish_exposure(
        project=project,
        bucket=bucket,
        exposure=exposure,
        dry_run=dry_run,
    )


@app.command()
def publish_all_exposures(
    project: str = "cal-itp-data-infra",
    bucket: str = "gs://calitp-publish",
    dry_run: bool = False,
) -> None:
    """
    Publish all exposures found in a dbt manifest.
    """

    with open("./target/manifest.json") as f:
        manifest = Manifest(**json.load(f))

    for name, exposure in manifest.exposures.items():
        _publish_exposure(
            project=project,
            bucket=bucket,
            exposure=exposure,
            dry_run=dry_run,
        )


if __name__ == "__main__":
    app()
