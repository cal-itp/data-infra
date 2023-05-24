import base64
import gzip
import json
import os
from enum import Enum
from typing import Any, Dict, List, Optional, Tuple, Union

import requests
import typer
from calitp_data.storage import get_fs  # type: ignore
from furl import furl
from geojson_pydantic import Feature, FeatureCollection, MultiPolygon, Point, Polygon
from geojson_pydantic.types import Position
from pydantic import BaseModel, HttpUrl, ValidationError, conlist, root_validator
from tqdm import tqdm

MAP_APP_URL_ENV_VAR = "CALITP_MAP_APP_URL"
MAP_APP_URL = os.getenv(MAP_APP_URL_ENV_VAR)


class Analysis(str, Enum):
    speedmaps = "speedmap"
    hqta_areas = "hqta_areas"
    hqta_stops = "hqta_stops"


class Tooltip(BaseModel):
    html: str
    style: Optional[Dict[str, Any]]


class Speedmap(BaseModel):
    stop_id: Optional[str]
    stop_name: Optional[str]
    route_id: Optional[str]
    tooltip: Tooltip
    color: conlist(int, min_items=3, max_items=3)  # we add alpha in the JS
    highlight_color: Optional[List[int]]

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


class Layer(BaseModel):
    name: str
    url: HttpUrl
    analysis: Optional[Analysis]


class BasemapConfig(BaseModel):
    url: str
    options: Dict[str, Any]


# Any positions in this are flipped from typical geojson
# leaflet wants lat/lon
class State(BaseModel):
    name: Optional[str]
    layers: conlist(Layer, min_items=1)
    lat_lon: Optional[Position]
    zoom: Optional[int]
    bbox: Optional[Tuple[Position, Position]]
    basemap_config: Optional[BasemapConfig]

    def validate_layers(
        self,
        data: bool = False,
        verbose: bool = False,
    ):
        for layer in self.layers:
            if verbose:
                typer.secho(
                    f"Checking that {typer.style(layer.url, fg=typer.colors.CYAN)} exists..."
                )
            resp = requests.head(layer.url)

            try:
                resp.raise_for_status()
            except requests.exceptions.HTTPError:
                typer.secho(f"Failed to find file at {layer.url}", fg=typer.colors.RED)
                raise

            if data:
                validate_geojson(layer.url, layer.analysis, verbose=verbose)

    @property
    def iframe_url(self) -> str:
        if not MAP_APP_URL:
            raise RuntimeError("Must provide MAP_APP_URL environment variable.")

        return (
            furl(MAP_APP_URL)
            .add(
                {
                    "state": base64.urlsafe_b64encode(
                        gzip.compress(self.json().encode())
                    ).decode()
                }
            )
            .url
        )
