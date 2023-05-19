import gzip
import json
from enum import Enum
from typing import Optional, Tuple, Union

import requests
import typer
import urllib3
from calitp_data.storage import get_fs  # type: ignore
from geojson_pydantic import Feature, FeatureCollection, MultiPolygon, Point, Polygon
from geojson_pydantic.types import Position
from pydantic import BaseModel, HttpUrl, ValidationError, root_validator
from tqdm import tqdm


class Analysis(str, Enum):
    speedmaps = "speedmap"
    hqta_areas = "hqta_areas"
    hqta_stops = "hqta_stops"


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


# Dict Props just mean properties are an arbitrary dictionary
ANALYSIS_FEATURE_TYPES = {
    Analysis.speedmaps: Feature[Polygon, Speedmap],
    Analysis.hqta_areas: Feature[Union[Polygon, MultiPolygon], HQTA],
    Analysis.hqta_stops: Feature[Point, HQTA],
}


def validate_geojson(
    path: str, analysis: Optional[Analysis] = None, verbose=False
) -> FeatureCollection:
    if verbose:
        typer.secho(f"Validating {typer.style(path, fg=typer.colors.CYAN)} contents...")

    is_compressed = path.endswith(".gz")

    if path.startswith("https://"):
        resp = requests.get(path)
        resp.raise_for_status()
        d = json.loads(
            gzip.decompress(resp.content).decode() if is_compressed else resp.text
        )
    else:
        openf = get_fs().open if path.startswith("gs://") else open

        with openf(path, "rb" if is_compressed else "r") as f:
            if is_compressed:
                f = gzip.GzipFile(fileobj=f)
            d = json.load(f)

    collection = FeatureCollection(**d)

    if analysis:
        analysis_class = ANALYSIS_FEATURE_TYPES[analysis]
        if verbose:
            typer.secho(
                f"Validating that features are {typer.style(str(analysis_class), fg=typer.colors.YELLOW)}..."
            )
        for feature in tqdm(collection.features):
            try:
                analysis_class(**feature.dict())
            except ValidationError:
                typer.secho(feature.json(), fg=typer.colors.RED)
                raise

    return collection


# Any positions in this are flipped from typical geojson
# leaflet wants lat/lon
class State(BaseModel):
    name: str
    url: HttpUrl
    lat_lon: Optional[Position]
    zoom: Optional[int]
    bbox: Optional[Tuple[Position, Position]]
    analysis: Optional[Analysis]

    def validate_url(
        self,
        data: bool = False,
        verbose: bool = False,
        analysis: Optional[Analysis] = None,
    ):
        if verbose:
            typer.secho(
                f"Checking that {typer.style(self.url, fg=typer.colors.CYAN)} exists..."
            )
        resp = urllib3.request("HEAD", self.url)  # type: ignore[operator]

        if resp.status != 200:
            msg = f"Failed to find file at {self.url}"
            if verbose:
                typer.secho(msg, fg=typer.colors.RED)
            raise FileNotFoundError(msg)

        if data:
            validate_geojson(self.url, analysis or self.analysis, verbose=verbose)
