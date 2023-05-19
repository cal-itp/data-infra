import base64
import gzip
import json
import sys
from typing import Optional

import typer

from . import Analysis, State
from . import validate_geojson as validate_geojson_func

app = typer.Typer()


@app.command()
def validate_geojson(path: str, analysis: Optional[Analysis] = None):
    collection = validate_geojson_func(path, analysis, verbose=True)

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
    analysis: Optional[Analysis] = None,
):
    if infile:
        typer.secho(f"Reading {infile}.")
        with open(infile) as f:
            contents = f.read()
    else:
        typer.secho("Reading from stdin...")
        contents = sys.stdin.read()

    if base64url:
        typer.secho("Decoding base64 contents...")
        byts = base64.urlsafe_b64decode(contents.encode())

        if compressed:
            byts = gzip.decompress(byts)

        contents = byts.decode()

    state = State(**json.loads(contents))
    state.validate_url(verbose=verbose, data=data, analysis=analysis)
    typer.secho("Validation successful!", fg=typer.colors.GREEN)
