__version__ = "0.1.0"

import gzip
import json
import logging
import os
import subprocess
import tempfile
import traceback
from datetime import datetime
from pathlib import Path
from typing import Dict, List, ClassVar, Optional

import pendulum
import typer
from calitp.storage import (
    fetch_all_in_partition,
    GTFSScheduleFeedExtract,
    get_fs,
    GTFSFeedType,
    JSONL_GZIP_EXTENSION,
    PartitionedGCSArtifact,
    ProcessingOutcome,
    JSONL_EXTENSION,
    SCHEDULE_RAW_BUCKET,
)
from pydantic import validator

JAVA_EXECUTABLE_PATH_KEY = "GTFS_SCHEDULE_VALIDATOR_JAVA_EXECUTABLE"
SCHEDULE_VALIDATOR_JAR_LOCATION_ENV_KEY = "GTFS_SCHEDULE_VALIDATOR_JAR"
JAR_DEFAULT = typer.Option(
    default=os.environ.get(SCHEDULE_VALIDATOR_JAR_LOCATION_ENV_KEY),
    help="Path to the GTFS Schedule Validator JAR",
)
SCHEDULE_VALIDATION_BUCKET = os.getenv("CALITP_BUCKET__GTFS_SCHEDULE_VALIDATION")
GTFS_VALIDATOR_VERSION = os.environ["GTFS_SCHEDULE_VALIDATOR_VERSION"]

app = typer.Typer()
logging.basicConfig()


# TODO: this could share some functionality with the RT validation artifact,
#   similar to the extracts sharing some functionality
class GTFSScheduleFeedValidation(PartitionedGCSArtifact):
    bucket: ClassVar[str] = SCHEDULE_VALIDATION_BUCKET
    partition_names: ClassVar[List[str]] = GTFSScheduleFeedExtract.partition_names
    table: ClassVar[str] = "validation_notices"
    ts: pendulum.DateTime
    base64_url: str
    extract_path: str
    system_errors: Dict

    @validator("filename", allow_reuse=True)
    def is_jsonl_gz(cls, v):
        assert v.endswith(JSONL_GZIP_EXTENSION)
        return v

    @property
    def dt(self) -> pendulum.Date:
        return self.ts.date()


class GTFSScheduleFeedExtractValidationOutcome(ProcessingOutcome):
    extract_path: str
    validation: Optional[GTFSScheduleFeedValidation]


# TODO: this and DownloadFeedsResult probably deserve a base class
class ScheduleValidationJobResult(PartitionedGCSArtifact):
    bucket: ClassVar[str] = SCHEDULE_VALIDATION_BUCKET
    table: ClassVar[str] = "validation_job_results"
    partition_names: ClassVar[List[str]] = ["dt"]
    dt: pendulum.Date
    outcomes: List[GTFSScheduleFeedExtractValidationOutcome]

    @validator("filename", allow_reuse=True)
    def is_jsonl(cls, v):
        assert v.endswith(JSONL_EXTENSION)
        return v

    @property
    def successes(self) -> List[GTFSScheduleFeedExtractValidationOutcome]:
        return [outcome for outcome in self.outcomes if outcome.success]

    @property
    def failures(self) -> List[GTFSScheduleFeedExtractValidationOutcome]:
        return [outcome for outcome in self.outcomes if not outcome.success]

    # TODO: I dislike having to exclude the records here
    #   I need to figure out the best way to have a single type represent the "metadata" of
    #   the content as well as the content itself
    def save(self, fs):
        self.save_content(
            fs=fs,
            content="\n".join(o.json() for o in self.outcomes).encode(),
            exclude={"outcomes"},
        )


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
        os.getenv(JAVA_EXECUTABLE_PATH_KEY, default="java"),
        "-jar",
        str(jar_path),
        "--input",
        str(zip_path),
        "--output_base",
        str(output_dir),
        "--country_code",
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
        ...,
        help="The date of data to validate.",
        formats=["%Y-%m-%d"],
    ),
) -> None:
    day = pendulum.instance(day).date()

    extracts: List[GTFSScheduleFeedExtract] = fetch_all_in_partition(
        cls=GTFSScheduleFeedExtract,
        bucket=SCHEDULE_RAW_BUCKET,
        table=GTFSFeedType.schedule,
        fs=get_fs(),
        partitions={
            "dt": day,
        },
        verbose=True,
    )

    if not extracts:
        typer.secho(
            "WARNING: found 0 extracts to process, exiting",
            fg=typer.colors.YELLOW,
        )
        return

    typer.secho(
        f"found {len(extracts)} to process for {day}",
        fg=typer.colors.MAGENTA,
    )
    fs = get_fs()
    outcomes = []

    for i, extract in enumerate(extracts, start=1):
        typer.secho(f"processing {i} of {len(extracts)}")
        try:
            with tempfile.TemporaryDirectory() as tmp_dir:
                zip_path = os.path.join(tmp_dir, extract.filename)
                typer.secho(
                    f"downloading {extract.path} to {zip_path}",
                    fg=typer.colors.GREEN,
                )
                fs.get_file(extract.path, zip_path)
                report, system_errors = execute_schedule_validator(
                    fs=fs,
                    zip_path=Path(zip_path),
                    output_dir=tmp_dir,
                )
            validation = GTFSScheduleFeedValidation(
                filename=f"validation_notices{JSONL_GZIP_EXTENSION}",
                ts=extract.ts,
                base64_url=extract.base64_url,
                extract_path=extract.path,
                system_errors=system_errors,
            )

            notices = [
                {
                    "metadata": {
                        "extract_path": extract.path,
                        "gtfs_validator_version": GTFS_VALIDATOR_VERSION,
                    },
                    **notice,
                }
                for notice in report["notices"]
            ]

            typer.secho(
                f"saving {len(notices)} validation notices to {validation.path}",
                fg=typer.colors.GREEN,
            )
            validation.save_content(
                content=gzip.compress(
                    "\n".join(json.dumps(notice) for notice in notices).encode()
                ),
                fs=fs,
            )
            outcomes.append(
                GTFSScheduleFeedExtractValidationOutcome(
                    success=True,
                    extract_path=extract.path,
                    validation=validation,
                )
            )
        except Exception as e:
            typer.secho(
                f"encountered exception on extract {extract.path}: {e}\n{traceback.format_exc()}",
                fg=typer.colors.RED,
            )
            outcomes.append(
                GTFSScheduleFeedExtractValidationOutcome(
                    success=False,
                    extract_path=extract.path,
                    exception=e,
                )
            )
    result = ScheduleValidationJobResult(
        filename="results.jsonl",
        dt=day,
        outcomes=outcomes,
    )
    typer.secho(
        f"got {len(result.successes)} successes and {len(result.failures)} failures",
        fg=typer.colors.MAGENTA,
    )
    typer.secho(
        f"saving {len(outcomes)} to {result.path}",
        fg=typer.colors.GREEN,
    )
    result.save(fs)
    assert len(extracts) == len(
        result.outcomes
    ), f"ended up with {len(outcomes)} outcomes from {len(extracts)} extracts"


if __name__ == "__main__":
    app()
