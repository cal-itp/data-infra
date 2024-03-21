__version__ = "0.1.0"

import concurrent.futures
import gzip
import json
import logging
import os
import subprocess
import tempfile
import traceback
from collections import defaultdict
from concurrent.futures import Future, ThreadPoolExecutor
from datetime import datetime
from pathlib import Path
from typing import ClassVar, Dict, List, Optional, Tuple, Type, Union

import pendulum
import sentry_sdk
import typer
from calitp_data_infra.storage import (  # type: ignore
    JSONL_EXTENSION,
    JSONL_GZIP_EXTENSION,
    SCHEDULE_RAW_BUCKET,
    GTFSDownloadConfig,
    GTFSFeedType,
    GTFSScheduleFeedExtract,
    PartitionedGCSArtifact,
    ProcessingOutcome,
    fetch_all_in_partition,
    get_fs,
)
from pydantic import BaseModel, validator
from slugify import slugify
from tqdm import tqdm

JAVA_EXECUTABLE = os.getenv("JAVA_EXECUTABLE", "java")
SCHEDULE_VALIDATOR_JAR_LOCATION_ENV_KEY = "GTFS_SCHEDULE_VALIDATOR_JAR"

V2_VALIDATOR_JAR = os.getenv("V2_VALIDATOR_JAR")
V3_VALIDATOR_JAR = os.getenv("V3_VALIDATOR_JAR")
V4_VALIDATOR_JAR = os.getenv("V4_VALIDATOR_JAR")
V4_1_VALIDATOR_JAR = os.getenv("V4_1_VALIDATOR_JAR")
V4_2_VALIDATOR_JAR = os.getenv("V4_2_VALIDATOR_JAR")
V5_VALIDATOR_JAR = os.getenv("V5_VALIDATOR_JAR")

JAR_DEFAULT = typer.Option(
    default=os.environ.get(SCHEDULE_VALIDATOR_JAR_LOCATION_ENV_KEY),
    help="Path to the GTFS Schedule Validator JAR",
)

SCHEDULE_VALIDATION_BUCKET = os.environ[
    "CALITP_BUCKET__GTFS_SCHEDULE_VALIDATION_HOURLY"
]

GTFS_VALIDATE_LIST_ERROR_THRESHOLD = float(
    os.getenv("GTFS_VALIDATE_LIST_ERROR_THRESHOLD", 0.99)
)

app = typer.Typer(pretty_exceptions_enable=False)
logging.basicConfig()

sentry_sdk.init()


class ScheduleValidationMetadata(BaseModel):
    extract_config: GTFSDownloadConfig
    gtfs_validator_version: str


# TODO: this could share some functionality with the RT validation artifact,
#   similar to the extracts sharing some functionality
class GTFSScheduleFeedValidation(PartitionedGCSArtifact):
    bucket: ClassVar[str] = SCHEDULE_VALIDATION_BUCKET
    partition_names: ClassVar[List[str]] = GTFSScheduleFeedExtract.partition_names
    table: ClassVar[str] = "validation_notices"
    ts: pendulum.DateTime
    extract_config: GTFSDownloadConfig
    system_errors: Dict
    validator_version: str

    @validator("filename", allow_reuse=True)
    def is_jsonl_gz(cls, v):
        assert v.endswith(JSONL_GZIP_EXTENSION)
        return v

    @property
    def dt(self) -> pendulum.Date:
        return self.ts.date()

    @property
    def base64_url(self) -> str:
        return self.extract_config.base64_encoded_url


class GTFSScheduleFeedExtractValidationOutcome(ProcessingOutcome):
    extract: GTFSScheduleFeedExtract
    validation: Optional[GTFSScheduleFeedValidation]


# TODO: this and DownloadFeedsResult probably deserve a base class
class ScheduleValidationJobResult(PartitionedGCSArtifact):
    bucket: ClassVar[str] = SCHEDULE_VALIDATION_BUCKET
    table: ClassVar[str] = "validation_job_results"
    partition_names: ClassVar[List[str]] = ["dt", "ts"]
    ts: pendulum.DateTime
    outcomes: List[GTFSScheduleFeedExtractValidationOutcome]

    @property
    def dt(self) -> pendulum.Date:
        return self.ts.date()

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


def log(*args, err=False, fg=None, pbar=None, **kwargs):
    # capture fg so we don't pass it to pbar
    if pbar:
        pbar.write(*args, **kwargs)
    else:
        typer.secho(*args, err=err, fg=fg, **kwargs)


def execute_schedule_validator(
    extract_ts: pendulum.DateTime,
    zip_path: Path,
    output_dir: Union[Path, str],
    pbar=None,
) -> Tuple[Dict, Dict, str]:
    if not isinstance(zip_path, Path):
        raise TypeError("must provide a path to the zip file")

    if extract_ts.date() < pendulum.Date(2022, 9, 15):
        versioned_jar_path = V2_VALIDATOR_JAR
        validator_version = "v2.0.0"
    elif extract_ts.date() < pendulum.Date(2022, 11, 16):
        versioned_jar_path = V3_VALIDATOR_JAR
        validator_version = "v3.1.1"
    elif extract_ts.date() < pendulum.Date(2023, 9, 1):
        versioned_jar_path = V4_VALIDATOR_JAR
        validator_version = "v4.0.0"
    elif extract_ts.date() < pendulum.Date(2024, 1, 20):
        versioned_jar_path = V4_1_VALIDATOR_JAR
        validator_version = "v4.1.0"
    else:
        versioned_jar_path = V4_2_VALIDATOR_JAR
        validator_version = "v4.2.0"

    assert versioned_jar_path

    args = [
        JAVA_EXECUTABLE,
        "-jar",
        versioned_jar_path,
        "--input",
        str(zip_path),
        "--output_base",
        str(output_dir),
        "--feed_name" if validator_version == "v2.0.0" else "--country_code",
        "us-na",
    ]

    report_path = Path(output_dir) / "report.json"
    system_errors_path = Path(output_dir) / "system_errors.json"

    log(f"executing schedule validator: {' '.join(args)}", pbar=pbar)
    subprocess.run(
        args,
        capture_output=True,
        check=True,
    )

    with open(report_path) as f:
        report = json.load(f)

    with open(system_errors_path) as f:
        system_errors = json.load(f)

    return report, system_errors, validator_version


def download_and_validate_extract(
    extract: GTFSScheduleFeedExtract, pbar=None
) -> GTFSScheduleFeedExtractValidationOutcome:
    fs = get_fs()
    with tempfile.TemporaryDirectory() as tmp_dir:
        zip_path = os.path.join(tmp_dir, extract.filename)
        log(
            f"downloading {extract.path} to {zip_path}",
            fg=typer.colors.GREEN,
            pbar=pbar,
        )
        fs.get_file(extract.path, zip_path)

        report, system_errors, validator_version = execute_schedule_validator(
            extract_ts=extract.ts,
            zip_path=Path(zip_path),
            output_dir=tmp_dir,
            pbar=pbar,
        )

    slugified_version = slugify(validator_version)
    validation = GTFSScheduleFeedValidation(
        filename=f"validation_notices_{slugified_version}{JSONL_GZIP_EXTENSION}",
        ts=extract.ts,
        extract_config=extract.config,
        system_errors=system_errors,
        validator_version=validator_version,
    )

    notices = [
        {
            "metadata": json.loads(
                ScheduleValidationMetadata(
                    extract_config=extract.config,
                    gtfs_validator_version=validator_version,
                ).json()
            ),
            **notice,
        }
        for notice in report["notices"]
    ]

    log(
        f"saving {len(notices)} validation notices to {validation.path}",
        fg=typer.colors.GREEN,
        pbar=pbar,
    )
    validation.save_content(
        content=gzip.compress(
            "\n".join(json.dumps(notice) for notice in notices).encode()
        ),
        fs=fs,
    )

    return GTFSScheduleFeedExtractValidationOutcome(
        success=True,
        extract=extract,
        validation=validation,
    )


@app.command()
def validate_extract(
    zip_path: Path,
    output_dir: Path,
    verbose=False,
) -> None:
    """"""
    execute_schedule_validator(
        extract_ts=pendulum.now(),
        zip_path=zip_path,
        output_dir=output_dir,
    )


# This is currently copy-pasted from Airflow utils
def get_schedule_files_in_hour(
    cls: Type[GTFSScheduleFeedExtract],
    bucket: str,
    table: str,
    period: pendulum.Period,
) -> Dict[pendulum.DateTime, List[GTFSScheduleFeedExtract]]:
    # __contains__ is defined as inclusive for pendulum.Period but we want to ignore the next hour
    # see https://github.com/apache/airflow/issues/25383#issuecomment-1198975178 for data_interval_end clarification
    assert (
        period.start.replace(minute=0, second=0, microsecond=0)
        == period.end.replace(minute=0, second=0, microsecond=0)
        and period.seconds == 3600 - 1
    ), f"{period} is not exactly 1 hour exclusive of end"
    day = pendulum.instance(period.start).date()
    files: List[GTFSScheduleFeedExtract]
    files, missing, invalid = fetch_all_in_partition(
        cls=cls,
        bucket=bucket,
        table=table,
        partitions={
            "dt": day,
        },
        verbose=True,
    )

    if missing or invalid:
        typer.secho(f"missing: {missing}")
        typer.secho(f"invalid: {invalid}")
        raise RuntimeError("found files with missing or invalid metadata; failing job")

    # Note: this is currently copy-pasted to the gtfs schedule validator
    files_in_hour = [f for f in files if f.ts in period]

    extract_map = defaultdict(list)
    for f in files_in_hour:
        extract_map[f.ts].append(f)

    typer.secho(
        f"found {len(files_in_hour)=} in {period=} ({len(extract_map.keys())} extracts)",
        fg=typer.colors.MAGENTA,
    )

    return extract_map


@app.command()
def validate_hour(
    hour: datetime = typer.Argument(
        ...,
        help="The start of the hour to validate.",
        formats=["%Y-%m-%dT%H"],
    ),
    verbose: bool = False,
    threads: int = 4,
    progress: bool = False,
) -> None:
    period = pendulum.instance(hour).add(hours=1, microseconds=-1) - pendulum.instance(
        hour
    )

    extracts: List[GTFSScheduleFeedExtract]
    extract_map = get_schedule_files_in_hour(
        cls=GTFSScheduleFeedExtract,
        bucket=SCHEDULE_RAW_BUCKET,
        table=GTFSFeedType.schedule,
        period=period,
    )

    if not extract_map:
        typer.secho(
            "WARNING: found 0 extracts to process, exiting",
            fg=typer.colors.YELLOW,
        )
        return

    for ts, extracts in extract_map.items():
        typer.secho(
            f"found {len(extracts)} to process for {ts}",
            fg=typer.colors.MAGENTA,
        )

        pbar = tqdm(total=len(extracts)) if progress else None
        exceptions = []
        outcomes = []
        fs = get_fs()

        with ThreadPoolExecutor(max_workers=threads) as pool:
            futures: Dict[Future, GTFSScheduleFeedExtract] = {
                pool.submit(
                    download_and_validate_extract,
                    extract=extract,
                    pbar=pbar,
                ): extract
                for i, extract in enumerate(extracts)
            }

            for future in concurrent.futures.as_completed(futures):
                extract = futures[future]
                if pbar:
                    pbar.update(1)

                try:
                    outcomes.append(future.result())
                except KeyboardInterrupt:
                    raise
                except Exception as e:
                    with sentry_sdk.push_scope() as scope:
                        if isinstance(e, subprocess.CalledProcessError):
                            # This is inefficient (we already downloaded in the thread)
                            # but is relatively rare for Schedule data
                            extract_hash = fs.stat(extract.path)["md5Hash"]
                            scope.fingerprint = [type(e), e.returncode, extract_hash]
                            # try to get the top of the stacktrace since this will be truncated; 1500 is just an estimate
                            scope.set_context(
                                "process", {"stderr": e.stderr.decode("utf-8")[-1500:]}
                            )
                        scope.set_context("extract", json.loads(extract.json()))
                        sentry_sdk.capture_exception(e, scope=scope)
                    log(
                        f"encountered exception on extract {extract.path}: {e}\n{traceback.format_exc()}",
                        fg=typer.colors.RED,
                        pbar=pbar,
                    )
                    if verbose and isinstance(e, subprocess.CalledProcessError):
                        log(
                            e.stderr.decode("utf-8"),
                            fg=typer.colors.RED,
                            pbar=pbar,
                        )

                    exceptions.append(e)
                    outcomes.append(
                        GTFSScheduleFeedExtractValidationOutcome(
                            success=False,
                            extract=extract,
                            exception=e,
                        )
                    )

        if pbar:
            del pbar

        result = ScheduleValidationJobResult(
            filename="results.jsonl",
            ts=ts,
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
        result.save(get_fs())

        assert len(extracts) == len(
            result.outcomes
        ), f"ended up with {len(outcomes)} outcomes from {len(extracts)} extracts"

        success_rate = len(result.successes) / len(extracts)
        if success_rate < GTFS_VALIDATE_LIST_ERROR_THRESHOLD:
            exc_str = "\n".join(str(tup) for tup in exceptions)
            msg = f"got {len(exceptions)} exceptions from validating {len(extracts)} extracts:\n{exc_str}"  # noqa: E231
            if exceptions:
                typer.secho(msg, err=True, fg=typer.colors.RED)
            raise RuntimeError(msg)


if __name__ == "__main__":
    app()
