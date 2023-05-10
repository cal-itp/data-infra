from typing import List

import typer
import urllib3
import yaml
from pydantic import BaseModel, HttpUrl
from tqdm import tqdm

app = typer.Typer()


class Layer(BaseModel):
    name: str
    url: HttpUrl


class LayerList(BaseModel):
    __root__: List[Layer]


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
