__version__ = "0.1.0"

import json
import os
import subprocess
import tempfile
import traceback
from datetime import datetime
from pathlib import Path
from typing import Dict

import pendulum
import typer
from calitp.storage import (
    fetch_all_in_partition,
    GTFSFeedExtractInfo,
    get_fs,
    GTFSScheduleFeedValidation,
    GTFSFeedType,
    JSONL_GZIP_EXTENSION,
    GTFSScheduleFeedExtractValidationOutcome,
    ScheduleValidationResult,
)

SCHEDULE_VALIDATOR_JAR_LOCATION_ENV_KEY = "GTFS_SCHEDULE_VALIDATOR_JAR"
JAR_DEFAULT = typer.Option(
    default=os.environ.get(SCHEDULE_VALIDATOR_JAR_LOCATION_ENV_KEY),
    help="Path to the GTFS Schedule Validator JAR",
)

app = typer.Typer()


def execute_schedule_validator(
    fs,
    zip_path: Path,
    output_dir: Path,
    jar_path: Path = os.environ.get(SCHEDULE_VALIDATOR_JAR_LOCATION_ENV_KEY),
    verbose=False,
) -> (Dict, Dict):
    if not isinstance(zip_path, Path):
        raise TypeError("must provide a path to the zip file")

    args = [
        "java",
        "-jar",
        str(jar_path),
        "--input",
        str(zip_path),
        "--output_base",
        str(output_dir),
        "--feed_name",
        "us-na",
    ]

    report_path = Path(output_dir) / "report.json"
    system_errors_path = Path(output_dir) / "system_errors.json"

    typer.secho(f"executing schedule validator: {' '.join(args)}")
    subprocess.run(
        args,
        capture_output=True,
    ).check_returncode()

    with open(report_path) as f:
        report = json.load(f)

    with open(system_errors_path) as f:
        system_errors = json.load(f)

    return report, system_errors


@app.command()
def validate_extract(
    zip_path: Path,
    output_dir: Path,
    jar_path: Path = os.environ.get(SCHEDULE_VALIDATOR_JAR_LOCATION_ENV_KEY),
    verbose=False,
) -> None:
    """"""
    execute_schedule_validator(
        fs=get_fs(),
        zip_path=zip_path,
        output_dir=output_dir,
        jar_path=jar_path,
        verbose=verbose,
    )


@app.command()
def validate_day(
    day: datetime = typer.Argument(
        default=pendulum.today(),
        help="The date of data to validate.",
        formats=["%Y-%m-%d"],
    ),
) -> None:
    day = pendulum.instance(day).date()

    extracts = fetch_all_in_partition(
        cls=GTFSFeedExtractInfo,
        table=GTFSFeedType.schedule,
        fs=get_fs(),
        partitions={
            "dt": day,
        },
        verbose=True,
    )

    typer.secho(f"found {len(extracts)} to process for {day}", fg=typer.colors.MAGENTA)
    fs = get_fs()
    outcomes = []

    for extract in extracts:
        try:
            with tempfile.TemporaryDirectory() as tmp_dir:
                zip_path = os.path.join(tmp_dir, extract.filename)
                typer.secho(
                    f"downloading {extract.path} to {zip_path}", fg=typer.colors.GREEN
                )
                fs.get_file(extract.path, zip_path)
                report, system_errors = execute_schedule_validator(
                    fs=fs,
                    zip_path=Path(zip_path),
                    output_dir=tmp_dir,
                )
            validation = GTFSScheduleFeedValidation(
                filename=f"validation_notices{JSONL_GZIP_EXTENSION}",
                extract=extract,
                system_errors=system_errors,
            )
            validation.save_content(
                content="\n".join(
                    json.dumps(notice) for notice in report["notices"]
                ).encode(),
                fs=fs,
            )
            outcomes.append(
                GTFSScheduleFeedExtractValidationOutcome(
                    success=True,
                    input_record=extract,
                    validation=validation,
                )
            )
            break
        except Exception as e:
            typer.secho(
                f"encountered exception on extract {extract.path}: {e}\n{traceback.format_exc()}",
                fg=typer.colors.RED,
            )
            outcomes.append(
                GTFSScheduleFeedExtractValidationOutcome(
                    success=False,
                    input_record=extract,
                    exception=e,
                )
            )
    result = ScheduleValidationResult(
        dt=day,
        outcomes=outcomes,
    )
    typer.secho(
        f"got {len(result.successes)} successes and {len(result.failures)} failures",
        fg=typer.colors.MAGENTA,
    )
    result.save(fs)
    assert len(extracts) == len(
        result.outcomes
    ), f"ended up with {len(outcomes)} outcomes from {len(extracts)} extracts"


if __name__ == "__main__":
    app()
