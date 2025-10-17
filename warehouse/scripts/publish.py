"""
Publishes various dbt models to various sources.

TODO: consider using https://github.com/ckan/ckanapi?
"""

import csv
import enum
import functools
import json
import os
import subprocess
import tempfile
from datetime import timedelta
from pathlib import Path
from typing import Any, BinaryIO, Dict, List, Literal, Optional, Tuple

import backoff
import gcsfs  # type: ignore
import geopandas as gpd  # type: ignore
import humanize
import pandas as pd
import pendulum
import requests
import shapely.geometry  # type: ignore
import shapely.wkt  # type: ignore
import typer
from dbt_artifacts import (
    CkanDestination,
    Exposure,
    Manifest,
    NodeModelMixin,
    TileFormat,
    TilesDestination,
)
from google.cloud import bigquery  # type: ignore
from pydantic import BaseModel, constr, validator
from requests import Response
from requests_toolbelt import MultipartEncoder  # type: ignore
from tqdm import tqdm

tqdm.pandas()

API_KEY = os.environ.get("CALITP_CKAN_GTFS_SCHEDULE_KEY")
DBT_ARTIFACTS_BUCKET = os.environ["CALITP_BUCKET__DBT_ARTIFACTS"]
MANIFEST_DEFAULT = f"{DBT_ARTIFACTS_BUCKET}/latest/manifest.json"
PUBLISH_BUCKET = os.environ["CALITP_BUCKET__PUBLISH"]

app = typer.Typer()

WGS84 = "EPSG:4326"  # "standard" lat/lon coordinate system
CHUNK_SIZE = (
    64 * 1024 * 1024
)  # 64MB, this comes from an example script provided by Caltrans


# once https://github.com/samuelcolvin/pydantic/pull/2745 is merged, we don't need this
class ListOfStrings(BaseModel):
    __root__: List[str]


# this is DDP-6
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


class YesOrNo(str, enum.Enum):
    y = "Y"
    n = "N"


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


def strip_modelname(x):
    """
    Models published for open data don't include dbt prefixes and internal labeling,
    so we need to strip that information from their names during publication
    """
    return x.replace("dim_", "").replace("fct_", "").replace("_latest", "")


def make_linestring(x):
    """
    This comes from https://github.com/cal-itp/data-analyses/blob/09f3b23c488e7ed1708ba721bf49121a925a8e0b/_shared_utils/shared_utils/geography_utils.py#L190

    It's specific to dim_shapes_geo, so we should update this when we actually start producing geojson
    """
    if len(x) == 0:
        return x
    if isinstance(x, str):
        return shapely.wkt.loads(x)
    # may have to convert wkt strings to points
    pts = [shapely.wkt.loads(pt) for pt in x] if isinstance(x[0], str) else x
    # shapely errors if the array contains only one point
    if len(pts) > 1:
        return shapely.geometry.LineString(pts)
    return pts[0]


@backoff.on_exception(
    backoff.constant,
    requests.exceptions.HTTPError,
    max_tries=2,
    interval=10,
)
def upload_to_ckan(
    url: str,
    fname: str,
    fsize: int,
    file: BinaryIO,
    resource_id: str,
):
    def ckan_request(action: str, data: Dict) -> Response:
        encoder = MultipartEncoder(fields=data)
        return requests.post(
            f"{url}/api/action/{action}",
            data=encoder,
            headers={"Content-Type": encoder.content_type, "X-CKAN-API-Key": API_KEY},  # type: ignore
        )

    if fsize <= CHUNK_SIZE:
        typer.secho(f"uploading {humanize.naturalsize(fsize)} to {resource_id}")
        response = requests.post(
            f"{url}/api/action/resource_update",
            data={"id": resource_id},
            headers={"Authorization": API_KEY},  # type: ignore
            files={"upload": file},
        )
        try:
            response.raise_for_status()
        except requests.exceptions.HTTPError:
            typer.secho(f"response body: {response.text}")
            raise
    else:
        typer.secho(
            f"uploading {humanize.naturalsize(fsize)} to {resource_id} in {humanize.naturalsize(CHUNK_SIZE)} chunks"
        )
        initiate_response = ckan_request(
            action="cloudstorage_initiate_multipart",
            data={
                "id": resource_id,
                "name": fname,
                "size": str(fsize),
            },
        )
        try:
            initiate_response.raise_for_status()
        except requests.exceptions.HTTPError:
            typer.secho(f"response body: {initiate_response.text}")
            raise
        upload_id = initiate_response.json()["result"]["id"]

        # https://stackoverflow.com/a/54989668
        chunker = functools.partial(file.read, CHUNK_SIZE)
        for i, chunk in enumerate(iter(chunker, b""), start=1):
            if i > 100:
                raise RuntimeError(
                    "stopping after 100 chunks, this should be re-considered"
                )
            try:
                typer.secho(f"uploading part {i} to multipart upload {upload_id}")
                ckan_request(
                    action="cloudstorage_upload_multipart",
                    data={
                        "id": resource_id,
                        "uploadId": upload_id,
                        "partNumber": str(
                            i
                        ),  # the server throws a 500 if this isn't a string
                        "upload": (fname, chunk, "text/plain"),
                    },
                ).raise_for_status()
            except Exception:
                ckan_request(
                    action="cloudstorage_abort_multipart",
                    data={
                        "id": resource_id,
                        "uploadId": upload_id,
                    },
                ).raise_for_status()
                raise
        ckan_request(
            action="cloudstorage_finish_multipart",
            data={
                "uploadId": upload_id,
                "id": resource_id,
                "save_action": "go-metadata",
            },
        ).raise_for_status()
        typer.secho(
            f"finished multipart upload_id {upload_id}", fg=typer.colors.MAGENTA
        )
        ckan_request(
            action="resource_patch",
            data={
                "id": resource_id,
                "multipart_name": fname,
                "url": fname,
                "size": str(fsize),
                "url_type": "upload",
            },
        ).raise_for_status()
        typer.secho(f"patched resource {resource_id}", fg=typer.colors.MAGENTA)


def _generate_exposure_documentation(
    exposure: Exposure,
) -> Tuple[List[Dict[str, Any]], List[Dict[str, Any]]]:
    assert (
        exposure.meta
        and exposure.meta.destinations is not None
        and exposure.depends_on is not None
    )
    try:
        resources = next(
            dest
            for dest in exposure.meta.destinations
            if isinstance(dest, CkanDestination)
        ).resources
    except StopIteration:
        raise ValueError(
            "cannot generate documentation for exposure without CKAN destination"
        )

    metadata_rows: List[Dict[str, Any]] = []
    dictionary_rows: List[Dict[str, Any]] = []

    for node in exposure.depends_on.resolved_nodes:  # type: ignore[attr-defined]
        assert exposure.meta is not None

        name = strip_modelname(node.name)
        description = node.description.replace("\n", " ")

        if name in resources and resources[name].description:
            description = resources[name].description  # type: ignore

        metadata_row = MetadataRow(
            dataset_name=strip_modelname(name),
            tags=[
                "transit",
                "gtfs",
                "gtfs-schedule",
                "bus",
                "rail",
                "ferry",
                "mobility",
            ],
            description=description,
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
            data_standard="https://gtfs.org/schedule/",
            notes=None,
            gis_theme=None,
            gis_horiz_accuracy="4m",
            gis_vert_accuracy="4m",
            gis_coordinate_system_epsg=exposure.meta.coordinate_system_epsg,
            gis_vert_datum_epsg=None,
        )
        metadata_rows.append(
            {
                k.upper(): v
                for k, v in json.loads(metadata_row.json(models_as_dict=False)).items()
            }
        )

        for name, column in node.columns.items():
            if column.meta.get("publish.include", False):
                field_description_authority = column.meta.get(
                    "ckan.authority", node.meta.get("ckan.authority")
                )
                assert field_description_authority is not None
                dictionary_row = DictionaryRow(
                    system_name="Cal-ITP GTFS-Ingest Pipeline",
                    table_name=strip_modelname(node.name),
                    field_name=column.name,
                    field_alias=None,
                    field_description=column.description,
                    field_description_authority=field_description_authority,
                    confidential="N",
                    sensitive="N",
                    pii="N",
                    pci="N",
                    field_type=column.meta.get("ckan.type", "STRING"),
                    field_length=column.meta.get("ckan.length", 1024),
                    field_precision=column.meta.get("ckan.precision"),
                    units=column.meta.get("ckan.units", None),
                    domain_type="Unrepresented",
                    allowable_min_value=None,
                    allowable_max_value=None,
                    usage_notes=None,
                )
                dictionary_rows.append(
                    {k.upper(): v for k, v in json.loads(dictionary_row.json()).items()}
                )
    return metadata_rows, dictionary_rows


def _publish_exposure(
    bucket: str, exposure: Exposure, publish: bool, model: Optional[str] = None
):
    ts = pendulum.now()
    assert (
        exposure.meta is not None
        and exposure.depends_on is not None
        and exposure.depends_on.nodes is not None
    )
    for destination in exposure.meta.destinations:
        with tempfile.TemporaryDirectory() as tmpdir:
            if isinstance(destination, CkanDestination):
                if len(exposure.depends_on.nodes) != len(destination.resources):
                    typer.secho(
                        f"WARNING: mismatch between {len(exposure.depends_on.nodes)} depends_on nodes and {len(destination.resources)} destination ids",
                        fg=typer.colors.YELLOW,
                    )

                metadata, dictionary = _generate_exposure_documentation(exposure)

                fs = gcsfs.GCSFileSystem()

                for rows, file, cls in (
                    (metadata, "metadata", MetadataRow),
                    (dictionary, "dictionary", DictionaryRow),
                ):
                    hive_path = destination.hive_path(
                        exposure, strip_modelname(file), bucket, dt=ts
                    )
                    typer.secho(
                        f"writing {len(rows)} rows to {hive_path}",
                        fg=typer.colors.GREEN,
                    )
                    with fs.open(hive_path, "w", newline="") as f:
                        writer = csv.DictWriter(
                            f, fieldnames=[key.upper() for key in cls.__fields__.keys()]  # type: ignore[attr-defined]
                        )
                        writer.writeheader()
                        for row in rows:
                            writer.writerow(row)

                # TODO: this should probably be driven by the depends_on nodes
                for model_name, resource in destination.resources.items():
                    if model and model != model_name:
                        typer.secho(
                            f"skipping {model_name} {resource.id}",
                            fg=typer.colors.YELLOW,
                        )
                        continue

                    typer.secho(
                        f"handling {model_name} {resource.id}", fg=typer.colors.MAGENTA
                    )
                    node = NodeModelMixin._instances[
                        f"model.calitp_warehouse.{model_name}"
                    ]

                    fpath = strip_modelname(
                        os.path.join(tmpdir, destination.filename(model_name))
                    )

                    df = pd.read_gbq(
                        str(node.select),
                        project_id=node.database,
                        progress_bar_type="tqdm",
                    )

                    precisions = {}

                    assert node.columns is not None
                    for name, column in node.columns.items():
                        assert column.meta is not None
                        ckan_precision = column.meta.get("ckan.precision")
                        if ckan_precision:
                            assert isinstance(ckan_precision, (str, int))
                            precisions[name] = int(ckan_precision)

                    if precisions:
                        typer.secho(
                            f"rounding {model_name} columns {','.join(precisions.keys())}",
                            fg=typer.colors.CYAN,
                        )
                        df = df.round(precisions)

                    df.to_csv(fpath, index=False)

                    hive_path = destination.hive_path(
                        exposure, strip_modelname(model_name), bucket, dt=ts
                    )
                    typer.secho(
                        f"writing {len(df)} rows ({humanize.naturalsize(os.stat(fpath).st_size)}) from {node.schema_table} to {hive_path}",
                        fg=typer.colors.GREEN,
                    )
                    fs.put_file(fpath, hive_path)

                    fname = destination.filename(model_name)
                    fsize = os.path.getsize(fpath)

                    publish_msg = f"uploading to {destination.url} {resource.id}"

                    if publish:
                        typer.secho(publish_msg, fg=typer.colors.GREEN)
                        try:
                            with open(fpath, "rb") as fp:
                                upload_to_ckan(
                                    url=destination.url,
                                    fname=fname,
                                    fsize=fsize,
                                    file=fp,
                                    resource_id=resource.id,
                                )
                        except requests.exceptions.HTTPError as e:
                            typer.secho(
                                f"Failed to upload to {fpath} due to error: {e}",
                                fg=typer.colors.RED,
                            )

                    else:
                        typer.secho(
                            f"would be {publish_msg} if --publish",
                            fg=typer.colors.YELLOW,
                        )
                    del df

            elif isinstance(destination, TilesDestination):
                layer_geojson_paths: Dict[str, Path] = {}
                for model in exposure.depends_on.nodes:
                    node = NodeModelMixin._instances[model]

                    geojsonl_fpath = Path(
                        os.path.join(tmpdir, f"{strip_modelname(node.name)}.geojsonl")
                    )

                    client = bigquery.Client(project=node.database)
                    typer.secho(f"querying {node.schema_table}")
                    # TODO: this is not great but we have to work around how BigQuery removes overlapping line segments
                    df = client.query(
                        f"select * from {node.schema_table}"
                    ).to_dataframe()
                    df["geometry_to_publish"] = df[destination.geo_column].apply(
                        make_linestring
                    )
                    gdf = gpd.GeoDataFrame(
                        data=df.drop(destination.geo_column, axis="columns"),
                        geometry="geometry_to_publish",
                        crs=WGS84,
                    )
                    # gdf = gdf.to_crs(WGS84)
                    if destination.metadata_columns:
                        gdf = gdf[
                            ["geometry_to_publish"] + destination.metadata_columns
                        ]
                    gdf.to_file(geojsonl_fpath, driver="GeoJSONSeq")
                    layer_geojson_paths[strip_modelname(node.name).title()] = (
                        geojsonl_fpath
                    )
                    hive_path = destination.hive_path(
                        exposure=exposure,
                        model=strip_modelname(node.name),
                        bucket=bucket,
                        dt=ts,
                    )

                    typer.secho(
                        f"writing {geojsonl_fpath} to {hive_path}",
                        fg=typer.colors.GREEN,
                    )
                    fs = gcsfs.GCSFileSystem(token="google_default")
                    fs.put(str(geojsonl_fpath), hive_path)

                if destination.tile_format == TileFormat.mbtiles:
                    mbtiles_path = os.path.join(tmpdir, "tiles.mbtiles")
                    args = [
                        "tippecanoe",
                        "-zg",
                        "-o",
                        mbtiles_path,
                        *[
                            f"--named-layer={layer}:{path}"  # noqa: E231
                            for layer, path in layer_geojson_paths.items()
                        ],
                    ]
                    typer.secho(f"running tippecanoe with args {args}")
                    subprocess.run(args).check_returncode()

                    tiles_hive_path = destination.tiles_hive_path(
                        exposure=exposure,
                        model=strip_modelname(node.name),
                        bucket=bucket,
                        dt=ts,
                    )

                    typer.secho(
                        f"writing {mbtiles_path} to {tiles_hive_path}",
                        fg=typer.colors.GREEN,
                    )
                    fs = gcsfs.GCSFileSystem(token="google_default")
                    fs.put(mbtiles_path, tiles_hive_path)
                else:
                    # -e for this when time
                    raise NotImplementedError


def read_manifest(path: str) -> Manifest:
    typer.secho(f"reading manifest from {path}", fg=typer.colors.MAGENTA)
    opener = gcsfs.GCSFileSystem().open if path.startswith("gs://") else open

    with opener(path) as f:
        return Manifest(**json.load(f))


@app.command()
def document_exposure(
    exposure: str,
    manifest: str = MANIFEST_DEFAULT,
    metadata_output: str = "./metadata.csv",
    dictionary_output: str = "./dictionary.csv",
) -> None:
    assert metadata_output.startswith("gs://") == dictionary_output.startswith(
        "gs://"
    ), "both outputs must be local or remote"

    metadata_rows, dictionary_rows = _generate_exposure_documentation(
        read_manifest(manifest).exposures[f"exposure.calitp_warehouse.{exposure}"]
    )

    typer.secho(
        f"writing out {metadata_output} and {dictionary_output}",
        fg=typer.colors.MAGENTA,
    )

    opener = gcsfs.GCSFileSystem().open if metadata_output.startswith("gs://") else open

    for rows, file, cls in (
        (metadata_rows, metadata_output, MetadataRow),
        (dictionary_rows, dictionary_output, DictionaryRow),
    ):
        with opener(file, "w", newline="") as f:
            writer = csv.DictWriter(
                f, fieldnames=[key.upper() for key in cls.__fields__.keys()]  # type: ignore[attr-defined]
            )
            writer.writeheader()
            for row in rows:
                writer.writerow(row)


@app.command()
def publish_exposure(
    exposure: str,
    bucket: str = typer.Option(
        PUBLISH_BUCKET,
        help="The bucket in which artifacts are persisted. Defaults to the value of $CALITP_BUCKET__PUBLISH.",
    ),
    manifest: str = MANIFEST_DEFAULT,
    publish: bool = typer.Option(
        False,
        help="If True, actually publish to external systems.",
    ),
    model: Optional[str] = None,
) -> None:
    """
    Only publish one exposure, by name.
    """
    if publish:
        assert not bucket.startswith("gs://test-"), "cannot publish with a test bucket!"

    actual_manifest = read_manifest(manifest)

    _publish_exposure(
        bucket=bucket,
        exposure=actual_manifest.exposures[f"exposure.calitp_warehouse.{exposure}"],
        publish=publish,
        model=model,
    )


@app.command()
def multipart_ckan_upload(
    resource_id: str,
    fpath: Path,
    url: str = "https://data.ca.gov",
):
    with open(fpath, "rb") as f:
        upload_to_ckan(
            url=url,
            fname=fpath.name,
            fsize=os.path.getsize(fpath),
            file=f,
            resource_id=resource_id,
        )


if __name__ == "__main__":
    app()
