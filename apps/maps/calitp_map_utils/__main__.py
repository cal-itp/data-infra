from typing import Optional

import typer

from . import Analysis
from . import validate_geojson as validate_geojson_func
from . import validate_state as validate_state_func

app = typer.Typer()


@app.command()
def validate_geojson(path: str, analysis: Optional[Analysis] = None):
    validate_geojson_func(path, analysis)


@app.command()
def validate_state(
    infile: Optional[str] = None,
    base64url: bool = False,
    compressed: bool = False,
    analysis: Optional[Analysis] = None,
):
    validate_state_func(
        infile=infile,
        base64url=base64url,
        compressed=compressed,
        analysis=analysis,
    )


app()
