import base64
import gzip
import json
import sys
from enum import Enum
from typing import Optional, Union

import typer
import urllib3
from calitp_data.storage import get_fs
from geojson_pydantic import Feature, FeatureCollection, MultiPolygon, Point, Polygon
from pydantic import BaseModel, HttpUrl, ValidationError, root_validator
from tqdm import tqdm

app = typer.Typer()


class State(BaseModel):
    url: HttpUrl


class Speedmap(BaseModel):
    stop_id: Optional[str]
    stop_name: Optional[str]
    route_id: Optional[str]

    @root_validator
    def some_identifier_exists(cls, values):
        assert any(key in values for key in ["stop_id", "stop_name", "route_id"])
        return values


class HQTA(BaseModel):
    hqta_type: str
    agency_name_primary: str
    agency_name_secondary: Optional[str]


class Analysis(str, Enum):
    speedmaps = "speedmap"
    hqta_areas = "hqta_areas"
    hqta_stops = "hqta_stops"


# Dict Props just mean properties are an arbitrary dictionary
ANALYSIS_FEATURE_TYPES = {
    Analysis.speedmaps: Feature[Polygon, Speedmap],
    Analysis.hqta_areas: Feature[Union[Polygon, MultiPolygon], HQTA],
    Analysis.hqta_stops: Feature[Point, HQTA],
}


@app.command()
def validate_geojson(path: str, analysis: Optional[Analysis] = None):
    typer.secho(f"Validating {path}...", fg=typer.colors.MAGENTA)
    fs = get_fs()
    openf = fs.open if path.startswith("gs://") else open
    is_compressed = path.endswith(".gz")

    with openf(path, "rb" if is_compressed else "r") as f:
        if is_compressed:
            f = gzip.GzipFile(fileobj=f)
        collection = FeatureCollection(**json.load(f))

    if analysis:
        analysis_class = ANALYSIS_FEATURE_TYPES[analysis]
        typer.secho(f"Validating that features are {analysis_class}...")
        for feature in tqdm(collection.features):
            try:
                analysis_class(**feature.dict())
            except ValidationError:
                typer.secho(feature.json(), fg=typer.colors.RED)
                raise

    typer.secho(
        f"Success! Validated {len(collection.features)} features.",
        fg=typer.colors.GREEN,
    )


@app.command()
def validate_state(
    infile: Optional[str] = None,
    base64url: bool = False,
    compressed: bool = False,
):
    if infile:
        typer.secho(f"Reading {infile}.", fg=typer.colors.MAGENTA)
        with open(infile) as f:
            contents = f.read()
    else:
        typer.secho("Reading from stdin...", fg=typer.colors.MAGENTA)
        contents = sys.stdin.read()

    if base64url:
        typer.secho("Decoding base64 contents...", fg=typer.colors.MAGENTA)
        contents = base64.urlsafe_b64decode(contents.encode())

        if compressed:
            contents = gzip.decompress(contents)

        contents = contents.decode()

    state = State(**json.loads(contents))
    typer.secho(f"Checking that {state.url} exists...", fg=typer.colors.MAGENTA)
    resp = urllib3.request("HEAD", state.url)

    if resp.status != 200:
        typer.secho(f"Failed to find file at {state.url}.", fg=typer.colors.RED)
        raise typer.Exit(1)

    typer.secho("Validation successful!", fg=typer.colors.GREEN)


if __name__ == "__main__":
    app()
