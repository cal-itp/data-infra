import json
from enum import Enum
from pathlib import Path
from typing import NoReturn

import gcsfs
import typer

from . import check_feeds


class OutputFormat(str, Enum):
    JSONL = "JSONL"
    JSON = "JSON"


def _assert_never(x: NoReturn) -> NoReturn:
    assert False, "Unhandled type: {}".format(type(x).__name__)


def main(
    yml_file: Path = typer.Argument("agencies.yml", help="A yml file containing urls"),
    csv_file: Path = typer.Option(None, help="A csv file (one url per line)"),
    url: str = typer.Option(None, help="URL to check instead of a file"),
    output: str = typer.Option(None, help="Path to a file to save output to."),
    output_format: OutputFormat = typer.Option(
        OutputFormat.JSONL, help="Output file format."
    ),
    progress: bool = typer.Option(False, help="Display progress bars"),
):
    results = check_feeds(
        yml_file=yml_file,
        csv_file=csv_file,
        url=url,
        progress=progress,
    )

    missing = []
    for url, data in results.items():
        statuses = [
            data["transitfeeds"]["status"],
            data["transitland"]["status"],
        ]
        if "present" not in statuses:
            missing.append(url)

    if missing:
        typer.echo(f"Unable to find {len(missing)}/{len(results)} urls:")
        for url in missing:
            typer.echo(url)
    else:
        matched = len(results) - len(missing)
        typer.echo(f"Found {matched}/{len(results)} urls were found")

    if output:
        typer.echo(f"saving results to {output}")
        if output_format is OutputFormat.JSON:
            content = json.dumps(results, indent=4)
        elif output_format is OutputFormat.JSONL:
            content = "\n".join(
                json.dumps({"url": url, **body}) for url, body in results.items()
            )
        else:
            _assert_never(output_format)

        if output.startswith("gs://"):
            fs = gcsfs.GCSFileSystem(token="google_default")
            fs.pipe(output, content.encode("utf-8"))
        else:
            with open(output, "w") as f:
                f.write(content)
        typer.echo(f"Results saved to {output}")


typer.run(main)
