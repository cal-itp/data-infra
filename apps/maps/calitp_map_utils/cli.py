import base64
import gzip
import json
import sys
from typing import Optional

import typer

from . import LayerType, State
from . import validate_geojson as validate_geojson_func

app = typer.Typer()


@app.command()
def validate_geojson(path: str, kind: Optional[LayerType] = None):
    collection = validate_geojson_func(path, kind, verbose=True)

    typer.secho(
        f"Success! Validated {len(collection.features)} features.",
        fg=typer.colors.GREEN,
    )


@app.command()
def validate_state(
    infile: Optional[str] = None,
    base64url: bool = False,
    compressed: bool = False,
    data: bool = False,
    verbose: bool = False,
    host: Optional[str] = None,
):
    if infile:
        typer.secho(f"Reading {infile}.")
        with open(infile) as f:
            contents = f.read()
    else:
        typer.secho("Reading from stdin...")
        contents = sys.stdin.read()

    if base64url:
        typer.secho("\tdecoding base64...")
        byts = base64.urlsafe_b64decode(contents.encode())

        if compressed:
            typer.secho("\tdecompressing...")
            byts = gzip.decompress(byts)

        contents = byts.decode()

    state = State(**json.loads(contents))
    state.validate_layers(verbose=verbose, data=data)
    typer.secho("Validation successful!", fg=typer.colors.GREEN)
    typer.secho(f"Creating URL from state {state.json()}...")
    typer.secho(f"URL: {state.iframe_url(host)}")
