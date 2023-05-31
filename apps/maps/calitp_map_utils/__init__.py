import base64
import gzip
import json
import os
from enum import Enum
from typing import Any, Dict, Optional, Tuple, Union

import requests
import typer
from calitp_data.storage import get_fs  # type: ignore
from furl import furl
from geojson_pydantic import Feature, FeatureCollection, MultiPolygon, Point, Polygon
from geojson_pydantic.geometries import Geometry
from geojson_pydantic.types import Position
from pydantic import BaseModel, Field, HttpUrl, ValidationError, conlist, root_validator
from tqdm import tqdm

MAP_APP_URL_ENV_VAR = "CALITP_MAP_APP_URL"
MAP_APP_URL = os.getenv(MAP_APP_URL_ENV_VAR)


class LayerType(str, Enum):  # name?
    speedmaps = "speedmap"
    hqta_areas = "hqta_areas"
    hqta_stops = "hqta_stops"
    state_highway_network = "state_highway_network"


class Tooltip(BaseModel):
    html: str
    style: Optional[Dict[str, Any]]


class Speedmap(BaseModel):
    stop_id: Optional[str]
    stop_name: Optional[str]
    route_id: Optional[str]
    tooltip: Optional[Tooltip]
    # we add alpha in the JS if only 3 colors are passed
    color: Optional[conlist(int, min_items=3, max_items=4)]
    highlight_color: Optional[conlist(int, min_items=3, max_items=4)]

    @root_validator
    def some_identifier_exists(cls, values):
        assert any(key in values for key in ["stop_id", "stop_name", "route_id"])
        return values


class HQTA(BaseModel):
    hqta_type: str
    agency_name_primary: str
    agency_name_secondary: Optional[str]


# Dict Props just mean properties are an arbitrary dictionary
LAYER_FEATURE_TYPES = {
    LayerType.speedmaps: Feature[Polygon, Speedmap],
    LayerType.hqta_areas: Feature[Union[Polygon, MultiPolygon], HQTA],
    LayerType.hqta_stops: Feature[Point, HQTA],
    LayerType.state_highway_network: Feature[Union[Polygon, MultiPolygon], Dict],
}


def validate_geojson(
    path: str, layer_type: Optional[LayerType] = None, verbose=False
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

    layer_type_class = LAYER_FEATURE_TYPES.get(layer_type, Feature[Geometry, Dict])

    if verbose:
        typer.secho(
            f"Validating that features are {typer.style(str(layer_type_class), fg=typer.colors.YELLOW)}..."
        )
    for feature in tqdm(collection.features):
        try:
            layer_type_class(**feature.dict())
        except ValidationError:
            typer.secho(feature.json(), fg=typer.colors.RED)
            raise

    return collection


class Layer(BaseModel):
    name: str
    url: HttpUrl
    typ: Optional[LayerType] = Field(alias="type")
    properties: Optional[Dict[str, Any]]


class BasemapConfig(BaseModel):
    url: str
    options: Dict[str, Any]


# Any positions in this are flipped from typical geojson
# leaflet wants lat/lon
class State(BaseModel):
    name: Optional[str]
    layers: conlist(
        Layer, min_items=1
    )  # this will not render in erdantic; needs to be List[Layer] but then pydantic2ts will not set min_items
    lat_lon: Optional[Position]
    zoom: Optional[int]
    bbox: Optional[Tuple[Position, Position]]
    basemap_config: Optional[BasemapConfig]
    legend_url: Optional[HttpUrl]

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
                validate_geojson(layer.url, layer.typ, verbose=verbose)

    def iframe_url(self, host: str = None) -> str:
        host = host or MAP_APP_URL
        if not host:
            raise RuntimeError(
                "Must provide host parameter or MAP_APP_URL environment variable."
            )

        return (
            furl(host)
            .add(
                {
                    "state": base64.urlsafe_b64encode(
                        gzip.compress(self.json(by_alias=True).encode())
                    ).decode()
                }
            )
            .url
        )
