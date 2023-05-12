import json
from enum import Enum
from pathlib import Path
from typing import Annotated, List, Optional

import typer
import urllib3
import yaml
from calitp_data.storage import get_fs
from geojson_pydantic import Feature, FeatureCollection, Polygon
from pydantic import BaseModel, HttpUrl, ValidationError, root_validator
from tqdm import tqdm

app = typer.Typer()


class Layer(BaseModel):
    name: str
    url: HttpUrl


class LayerList(BaseModel):
    __root__: List[Layer]


class Speedmap(BaseModel):
    stop_id: Optional[str]
    stop_name: Optional[str]
    route_id: Optional[str]

    @root_validator
    def some_identifier_exists(cls, values):
        assert any(key in values for key in ["stop_id", "stop_name", "route_id"])
        return values


class Analysis(str, Enum):
    speedmap = "speedmap"


ANALYSIS_MAP = {
    Analysis.speedmap: Feature[Polygon, Speedmap],
}


@app.command()
def validate_geojson(path: str, analysis: Optional[Analysis] = None):
    typer.secho(f"Validating {path}...", fg=typer.colors.MAGENTA)
    fs = get_fs()
    openf = fs.open if path.startswith("gs://") else open

    with openf(path) as f:
        collection = FeatureCollection(**json.load(f))

    if analysis:
        analysis_class = ANALYSIS_MAP[analysis]
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
def validate_site(
    index: Annotated[
        Path,
        typer.Option(
            ...,
            exists=True,
            file_okay=True,
            dir_okay=False,
        ),
    ],
    geojson_root: str,
):
    typer.secho(f"Validating index at {index}.")

    typer.secho(f"Validating GeoJSON data starting at {geojson_root}.")


@app.command()
def build_index(
    infile: str = "layers.yaml",
    outfile: str = "static/layers.json",
):
    typer.secho(f"Reading {infile}.")
    with open(infile) as inf:
        layers = LayerList.parse_obj(yaml.safe_load(inf.read()))

    typer.secho("Checking that URLs exist.")
    for layer in tqdm(layers.__root__):
        # use urllib3 because requests hangs?
        resp = urllib3.request("HEAD", layer.url)
        assert resp.status == 200

    with open(outfile, "w") as outf:
        outf.write(layers.json())

    typer.secho(f"Layers written to {outfile}.")


if __name__ == "__main__":
    app()
