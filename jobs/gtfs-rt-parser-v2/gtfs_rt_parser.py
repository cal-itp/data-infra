"""
Parses binary RT feeds and writes them back to GCS as gzipped newline-delimited JSON
"""
import base64
import concurrent.futures
import copy
import datetime
import gzip
import hashlib
import json
import os
import subprocess
import sys
import tempfile
import traceback
from collections import defaultdict
from concurrent.futures import Future, ThreadPoolExecutor
from enum import Enum
from functools import lru_cache
from pathlib import Path
from typing import Any, ClassVar, Dict, List, Optional, Sequence, Tuple, Union

import backoff  # type: ignore
import gcsfs  # type: ignore
import pendulum
import sentry_sdk
import typer
from aiohttp.client_exceptions import (
    ClientOSError,
    ClientResponseError,
    ServerDisconnectedError,
)
from calitp_data_infra.storage import (  # type: ignore
    JSONL_GZIP_EXTENSION,
    GTFSDownloadConfig,
    GTFSFeedExtract,
    GTFSFeedType,
    GTFSRTFeedExtract,
    GTFSScheduleFeedExtract,
    PartitionedGCSArtifact,
    ProcessingOutcome,
    fetch_all_in_partition,
    get_fs,
    make_name_bq_safe,
)
from google.cloud.storage import Blob  # type: ignore
from google.protobuf import json_format
from google.protobuf.message import DecodeError
from google.transit import gtfs_realtime_pb2  # type: ignore
from pydantic import BaseModel, Field, validator
from tqdm import tqdm

RT_VALIDATOR_JAR_LOCATION_ENV_KEY = "GTFS_RT_VALIDATOR_JAR"
JAR_DEFAULT = typer.Option(
    os.environ.get(RT_VALIDATOR_JAR_LOCATION_ENV_KEY),
    help="Path to the GTFS RT Validator JAR",
)

RT_PARSED_BUCKET = os.environ["CALITP_BUCKET__GTFS_RT_PARSED"]
RT_VALIDATION_BUCKET = os.environ["CALITP_BUCKET__GTFS_RT_VALIDATION"]
GTFS_RT_VALIDATOR_VERSION = os.environ["GTFS_RT_VALIDATOR_VERSION"]

app = typer.Typer(pretty_exceptions_enable=False)

# mypy: disable-error-code="attr-defined"
sentry_sdk.utils.MAX_STRING_LENGTH = 2048  # default is 512 which will cut off validator stderr stacktrace; see https://stackoverflow.com/a/58124859
sentry_sdk.init()


def make_dict_bq_safe(d: Dict[str, Any]) -> Dict[str, Any]:
    return {
        make_name_bq_safe(key): make_dict_bq_safe(value)
        if isinstance(value, dict)
        else value
        for key, value in d.items()
    }


def make_pydantic_model_bq_safe(model: BaseModel) -> Dict[str, Any]:
    """
    This is ugly but I think it's the best option until https://github.com/pydantic/pydantic/issues/1409
    """
    return make_dict_bq_safe(json.loads(model.json()))


class MissingMetadata(Exception):
    pass


class InvalidMetadata(Exception):
    pass


class RTProcessingStep(str, Enum):
    parse = "parse"
    validate = "validate"


class RTParsingMetadata(BaseModel):
    extract_ts: pendulum.DateTime
    extract_config: GTFSDownloadConfig


class RTValidationMetadata(BaseModel):
    extract_ts: pendulum.DateTime
    extract_config: GTFSDownloadConfig
    gtfs_validator_version: str


def log(*args, err=False, fg=None, pbar=None, **kwargs):
    # capture fg so we don't pass it to pbar
    if pbar:
        pbar.write(*args, **kwargs, file=sys.stderr if err else None)
    else:
        typer.secho(*args, err=err, fg=fg, **kwargs)


def upload_if_records(
    fs,
    tmp_dir: str,
    artifact: PartitionedGCSArtifact,
    records: Sequence[Union[Dict, BaseModel]],
    pbar=None,
):
    # BigQuery fails when trying to parse empty files, so shouldn't write them
    if not records:
        log(
            f"WARNING: no records found for {artifact.path}, skipping upload",
            fg=typer.colors.YELLOW,
            pbar=pbar,
        )
        return

    log(
        f"writing {len(records)} lines to {artifact.path}",
        pbar=pbar,
    )
    with tempfile.NamedTemporaryFile(mode="wb", delete=False, dir=tmp_dir) as f:
        gzipfile = gzip.GzipFile(mode="wb", fileobj=f)
        encoded = (
            r.json() if isinstance(r, BaseModel) else json.dumps(r) for r in records
        )
        gzipfile.write("\n".join(encoded).encode("utf-8"))
        gzipfile.close()

    put_with_retry(fs, f.name, artifact.path)


class NoScheduleDataSpecified(Exception):
    pass


class ScheduleDataNotFound(Exception):
    pass


@lru_cache
def get_schedule_extracts_for_day(
    dt: pendulum.Date,
) -> Dict[str, GTFSScheduleFeedExtract]:
    extracts: List[GTFSScheduleFeedExtract]
    extracts, missing, invalid = fetch_all_in_partition(
        cls=GTFSScheduleFeedExtract,
        partitions={
            "dt": dt,
        },
    )

    # Explicitly put extracts in timestamp order so dict construction below sets
    # values to the most recent extract for a given base64_url
    extracts.sort(key=lambda extract: extract.ts)

    return {extract.base64_url: extract for extract in extracts}


class RTHourlyAggregation(PartitionedGCSArtifact):
    partition_names: ClassVar[List[str]] = ["dt", "hour", "base64_url"]
    step: RTProcessingStep
    first_extract: GTFSRTFeedExtract
    extracts: List[GTFSRTFeedExtract] = Field(..., exclude=True)

    @property
    def feed_type(self) -> GTFSFeedType:
        return self.first_extract.feed_type

    @property
    def hour(self) -> pendulum.DateTime:
        return self.first_extract.hour

    @property
    def base64_url(self) -> str:
        return self.first_extract.base64_url

    @property
    def bucket(self) -> str:
        if self.step == RTProcessingStep.parse:
            return RT_PARSED_BUCKET
        if self.step == RTProcessingStep.validate:
            return RT_VALIDATION_BUCKET
        raise RuntimeError("we should not be here")

    @property
    def table(self):
        if self.step == RTProcessingStep.parse:
            return self.feed_type
        if self.step == RTProcessingStep.validate:
            return f"{self.feed_type}_validation_notices"
        raise RuntimeError("we should not be here")

    @property
    def dt(self) -> pendulum.Date:
        return self.hour.date()

    @property
    def name_hash(self) -> str:
        return hashlib.md5(self.name.encode("utf-8")).hexdigest()

    @property
    def unique_filename(self):
        """Used for on-disk handling."""
        return f"{self.name_hash}{JSONL_GZIP_EXTENSION}"

    @validator("extracts", allow_reuse=True)
    def extracts_have_the_same_signature(cls, v: List[GTFSRTFeedExtract]):
        for attr in ("feed_type", "hour", "base64_url"):
            assert len(set(getattr(extract, attr) for extract in v)) == 1
        # schedules = set(extract.schedule_extract for extract in v)
        return v

    # this is kinda weird living on the hour, but the hour is basically our processing context
    def local_paths_to_extract(self, root) -> Dict[str, GTFSRTFeedExtract]:
        return {
            os.path.join(root, extract.timestamped_filename): extract
            for extract in self.extracts
        }


class RTFileProcessingOutcome(ProcessingOutcome):
    # an extract is technically optional if we have a blob missing metadata
    step: RTProcessingStep
    extract: Optional[GTFSRTFeedExtract]
    header: Optional[Dict[Any, Any]]
    aggregation: Optional[RTHourlyAggregation]
    blob_path: Optional[str]
    process_stderr: Optional[str]

    @validator("aggregation", allow_reuse=True, always=True)
    def aggregation_exists_if_success(cls, v, values):
        assert (
            values["success"] or v is None
        ), "aggregation cannot exist if there is a failure"
        return v

    @validator("blob_path", allow_reuse=True, always=True)
    def blob_path_cannot_exist_if_an_extract_exists(cls, v, values):
        assert (v is None) != (
            values["extract"] is None
        ), "one of blob or extract must be null"
        return v

    @validator("header", allow_reuse=True)
    def header_must_exist_for_successful_parses(cls, v, values):
        if values["success"] and values["step"] == RTProcessingStep.parse:
            assert v
        return v

    @validator("process_stderr", allow_reuse=True)
    def stderr_must_exist_if_subprocess_error(cls, v, values):
        if isinstance(values.get("exception"), subprocess.CalledProcessError):
            assert v
        return v


class GTFSRTJobResult(PartitionedGCSArtifact):
    step: RTProcessingStep
    feed_type: GTFSFeedType
    hour: pendulum.DateTime
    partition_names: ClassVar[List[str]] = ["dt", "hour"]
    outcomes: List[RTFileProcessingOutcome]

    @property
    def bucket(self) -> str:
        if self.step == RTProcessingStep.parse:
            return RT_PARSED_BUCKET
        if self.step == RTProcessingStep.validate:
            return RT_VALIDATION_BUCKET
        raise RuntimeError("we should not be here")

    @property
    def table(self):
        if self.step == RTProcessingStep.parse:
            return f"{self.feed_type}_outcomes"
        if self.step == RTProcessingStep.validate:
            return f"{self.feed_type}_validation_outcomes"
        raise RuntimeError("we should not be here")

    @property
    def dt(self) -> pendulum.Date:
        return self.hour.date()


def save_job_result(fs: gcsfs.GCSFileSystem, result: GTFSRTJobResult):
    typer.secho(
        f"saving {len(result.outcomes)} outcomes to {result.path}",
        fg=typer.colors.GREEN,
    )
    # TODO: I dislike having to exclude the records here
    #   I need to figure out the best way to have a single type represent the "metadata" of
    #   the content as well as the content itself
    result.save_content(
        fs=fs,
        content="\n".join(
            (json.dumps(make_pydantic_model_bq_safe(o)) for o in result.outcomes)
        ).encode(),
        exclude={"outcomes"},
    )


def fatal_code(e):
    return isinstance(e, ClientResponseError) and e.status == 404


@backoff.on_exception(
    backoff.expo,
    exception=(ClientOSError, ClientResponseError, ServerDisconnectedError),
    max_tries=3,
    giveup=fatal_code,
)
def get_with_retry(fs, *args, **kwargs):
    return fs.get(*args, **kwargs)


@backoff.on_exception(
    backoff.expo,
    exception=(ClientOSError, ClientResponseError, ServerDisconnectedError),
    max_tries=3,
)
def put_with_retry(fs, *args, **kwargs):
    return fs.put(*args, **kwargs)


def download_gtfs_schedule_zip(
    fs,
    schedule_extract: GTFSFeedExtract,
    dst_dir: str,
    pbar=None,
) -> str:
    # fetch and zip gtfs schedule
    full_dst_path = "/".join([dst_dir, schedule_extract.filename])
    log(
        f"Fetching gtfs schedule data from {schedule_extract.path} to {full_dst_path}",
        pbar=pbar,
    )
    get_with_retry(fs, schedule_extract.path, full_dst_path)

    # https://github.com/MobilityData/gtfs-realtime-validator/issues/92
    # try:
    #     os.remove(os.path.join(dst_path, "areas.txt"))
    # except FileNotFoundError:
    #     pass

    return full_dst_path


def execute_rt_validator(
    gtfs_file: str, rt_path: str, jar_path: Path, verbose=False, pbar=None
):
    log(f"validating {rt_path} with {gtfs_file}", fg=typer.colors.MAGENTA, pbar=pbar)

    args = [
        "java",
        "-jar",
        str(jar_path),
        "-gtfs",
        gtfs_file,
        "-gtfsRealtimePath",
        rt_path,
        "-sort",
        "name",
    ]

    log(f"executing rt_validator: {' '.join(args)}", pbar=pbar)
    subprocess.run(
        args,
        capture_output=True,
        check=True,
    )


def validate_and_upload(
    fs,
    jar_path: Path,
    dst_path_rt: str,
    tmp_dir: str,
    hour: RTHourlyAggregation,
    gtfs_zip: str,
    verbose: bool = False,
    pbar=None,
) -> List[RTFileProcessingOutcome]:
    execute_rt_validator(
        gtfs_zip,
        dst_path_rt,
        jar_path=jar_path,
        verbose=verbose,
        pbar=pbar,
    )

    records_to_upload = []
    outcomes = []
    for local_path, extract in hour.local_paths_to_extract(dst_path_rt).items():
        results_path = local_path + ".results.json"
        try:
            with open(results_path) as f:
                records = json.load(f)
        except FileNotFoundError as e:
            # This exception was previously generating the error "[Errno 2] No such file or directory"
            msg = f"WARNING: no validation output file found in {results_path} for {extract.path}"
            if verbose:
                log(
                    msg,
                    fg=typer.colors.YELLOW,
                    pbar=pbar,
                )
            outcomes.append(
                RTFileProcessingOutcome(
                    step=hour.step,
                    success=False,
                    exception=e,
                    extract=extract,
                )
            )
            continue

        records_to_upload.extend(
            [
                {
                    "metadata": json.loads(
                        RTValidationMetadata(
                            extract_ts=extract.ts,
                            extract_config=extract.config,
                            gtfs_validator_version=GTFS_RT_VALIDATOR_VERSION,
                        ).json()
                    ),
                    **record,
                }
                for record in records
            ]
        )

        outcomes.append(
            RTFileProcessingOutcome(
                step=hour.step,
                success=True,
                extract=extract,
                aggregation=hour,
            )
        )

    upload_if_records(
        fs,
        tmp_dir,
        artifact=hour,
        records=records_to_upload,
        pbar=pbar,
    )

    return outcomes


def parse_and_upload(
    fs,
    dst_path_rt,
    tmp_dir,
    hour: RTHourlyAggregation,
    verbose=False,
    pbar=None,
) -> List[RTFileProcessingOutcome]:
    written = 0
    outcomes = []
    gzip_fname = str(tmp_dir + hour.unique_filename)

    # ParseFromString() seems to not release memory well, so manually handle
    # writing to the gzip and cleaning up after ourselves

    with gzip.open(gzip_fname, "w") as gzipfile:
        for extract in hour.extracts:
            feed = gtfs_realtime_pb2.FeedMessage()

            try:
                with open(
                    os.path.join(dst_path_rt, extract.timestamped_filename), "rb"
                ) as f:
                    feed.ParseFromString(f.read())
                parsed = json_format.MessageToDict(feed)
            except DecodeError as e:
                if verbose:
                    log(
                        f"WARNING: DecodeError for {str(extract.path)}",
                        fg=typer.colors.YELLOW,
                        pbar=pbar,
                    )
                outcomes.append(
                    RTFileProcessingOutcome(
                        step=RTProcessingStep.parse,
                        success=False,
                        exception=e,
                        extract=extract,
                    )
                )
                continue

            if not parsed:
                msg = f"WARNING: no parsed dictionary found in {str(extract.path)}"
                if verbose:
                    log(
                        msg,
                        fg=typer.colors.YELLOW,
                        pbar=pbar,
                    )
                outcomes.append(
                    RTFileProcessingOutcome(
                        step=RTProcessingStep.parse,
                        success=False,
                        exception=ValueError(msg),
                        extract=extract,
                    )
                )
                continue

            if "entity" not in parsed:
                msg = f"WARNING: no parsed entity found in {str(extract.path)}"
                if verbose:
                    log(
                        msg,
                        fg=typer.colors.YELLOW,
                        pbar=pbar,
                    )
                outcomes.append(
                    RTFileProcessingOutcome(
                        step=RTProcessingStep.parse,
                        success=True,
                        extract=extract,
                        header=parsed["header"],
                    )
                )
                continue

            for record in parsed["entity"]:
                gzipfile.write(
                    (
                        json.dumps(
                            {
                                "header": parsed["header"],
                                # back and forth so we use pydantic serialization
                                "metadata": json.loads(
                                    RTParsingMetadata(
                                        extract_ts=extract.ts,
                                        extract_config=extract.config,
                                    ).json()
                                ),
                                **copy.deepcopy(record),
                            }
                        )
                        + "\n"
                    ).encode("utf-8")
                )
                written += 1
            outcomes.append(
                RTFileProcessingOutcome(
                    step=RTProcessingStep.parse,
                    success=True,
                    extract=extract,
                    aggregation=hour,
                    header=parsed["header"],
                )
            )
            del parsed

    if written:
        log(
            f"writing {written} lines to {hour.path}",
            pbar=pbar,
        )
        put_with_retry(fs, gzip_fname, hour.path)
    else:
        log(
            f"WARNING: no records at all for {hour.path}",
            fg=typer.colors.YELLOW,
            pbar=pbar,
        )

    return outcomes


# Originally this whole function was retried, but tmpdir flakiness will throw
# exceptions in backoff's context, which ruins things
def parse_and_validate(
    hour: RTHourlyAggregation,
    jar_path: Path,
    verbose: bool = False,
    pbar=None,
) -> List[RTFileProcessingOutcome]:
    with tempfile.TemporaryDirectory() as tmp_dir:
        with sentry_sdk.push_scope() as scope:
            scope.set_tag("config_feed_type", hour.first_extract.config.feed_type)
            scope.set_tag("config_name", hour.first_extract.config.name)
            scope.set_tag("config_url", hour.first_extract.config.url)
            scope.set_context("RT Hourly Aggregation", json.loads(hour.json()))

            fs = get_fs()
            dst_path_rt = f"{tmp_dir}/rt_{hour.name_hash}/"
            get_with_retry(
                fs,
                rpath=[
                    extract.path
                    for extract in hour.local_paths_to_extract(dst_path_rt).values()
                ],
                lpath=list(hour.local_paths_to_extract(dst_path_rt).keys()),
            )

            if hour.step == RTProcessingStep.validate:
                if not hour.extracts[0].config.schedule_url_for_validation:
                    return [
                        RTFileProcessingOutcome(
                            step=hour.step,
                            success=False,
                            extract=extract,
                            exception=NoScheduleDataSpecified(),
                        )
                        for extract in hour.extracts
                    ]

                try:
                    first_extract = hour.extracts[0]
                    extract_day = first_extract.dt
                    for target_date in reversed(
                        list(extract_day - extract_day.subtract(days=7))
                    ):  # Fall back to most recent available schedule within 7 days
                        try:
                            schedule_extract = get_schedule_extracts_for_day(
                                target_date
                            )[first_extract.config.base64_validation_url]

                            scope.set_context(
                                "Schedule Extract", json.loads(schedule_extract.json())
                            )

                            gtfs_zip = download_gtfs_schedule_zip(
                                fs,
                                schedule_extract=schedule_extract,
                                dst_dir=tmp_dir,
                                pbar=pbar,
                            )

                            break
                        except (KeyError, FileNotFoundError):
                            print(
                                f"no schedule data found for {first_extract.path} and day {target_date}"
                            )
                    else:
                        raise ScheduleDataNotFound(
                            f"no recent schedule data found for {first_extract.path}"
                        )

                    return validate_and_upload(
                        fs=fs,
                        jar_path=jar_path,
                        dst_path_rt=dst_path_rt,
                        tmp_dir=tmp_dir,
                        hour=hour,
                        gtfs_zip=gtfs_zip,
                        verbose=verbose,
                        pbar=pbar,
                    )

                # these are the only two types of errors we expect; let any others bubble up
                except (ScheduleDataNotFound, subprocess.CalledProcessError) as e:
                    stderr = None

                    fingerprint: List[Any] = [
                        type(e),
                        # convert back to url manually, I don't want to mess around with the hourly class
                        base64.urlsafe_b64decode(hour.base64_url.encode()).decode(),
                    ]
                    if isinstance(e, subprocess.CalledProcessError):
                        fingerprint.append(e.returncode)
                        stderr = e.stderr.decode("utf-8")

                        # get the end of stderr, just enough to fit in MAX_STRING_LENGTH defined above
                        scope.set_context(
                            "Process", {"stderr": e.stderr.decode("utf-8")[-2000:]}
                        )

                        # we could also use a custom exception for this
                        if "Unexpected end of ZLIB input stream" in stderr:
                            fingerprint.append("Unexpected end of ZLIB input stream")

                    scope.fingerprint = fingerprint
                    sentry_sdk.capture_exception(e, scope=scope)

                    if verbose:
                        log(
                            f"{str(e)} thrown for {hour.path}",
                            fg=typer.colors.RED,
                            pbar=pbar,
                        )
                        if isinstance(e, subprocess.CalledProcessError):
                            log(
                                e.stderr.decode("utf-8"),
                                fg=typer.colors.YELLOW,
                                pbar=pbar,
                            )

                    return [
                        RTFileProcessingOutcome(
                            step=hour.step,
                            success=False,
                            extract=extract,
                            exception=e,
                            process_stderr=stderr,
                        )
                        for extract in hour.extracts
                    ]

            if hour.step == RTProcessingStep.parse:
                return parse_and_upload(
                    fs=fs,
                    dst_path_rt=dst_path_rt,
                    tmp_dir=tmp_dir,
                    hour=hour,
                    verbose=verbose,
                    pbar=pbar,
                )

            raise RuntimeError("we should not be here")

class HourlyFeedFiles:
    def __init__(self, files: List[GTFSRTFeedExtract], files_missing_metadata: List[Blob], files_invalid_metadata: List[Blob]):
        self.files = files
        self.files_missing_metadata = files_missing_metadata
        self.files_invalid_metadata = files_invalid_metadata

    def total(self) -> int:
        return len(self.files) + len(self.files_missing_metadata) + len(self.files_invalid_metadata)

    def valid(self) -> bool:
        return not self.files or len(self.files) / self.total() > 0.99

class FeedStorage:
    def __init__(self, feed_type: GTFSFeedType):
        self.feed_type = feed_type

    @lru_cache
    def get_hour(self, hour: datetime.datetime) -> HourlyFeedFiles:
        pendulum_hour = pendulum.instance(hour, tz="Etc/UTC")
        files, files_missing_metadata, files_invalid_metadata = fetch_all_in_partition(
            cls=GTFSRTFeedExtract,
            partitions={
                "dt": pendulum_hour.date(),
                "hour": pendulum_hour,
            },
            table=self.feed_type,
            verbose=True,
        )
        return HourlyFeedFiles(files, files_missing_metadata, files_invalid_metadata)

@app.command()
def main(
    step: RTProcessingStep,
    feed_type: GTFSFeedType,
    hour: datetime.datetime,
    limit: int = 0,
    progress: bool = typer.Option(
        False,
        help="If true, display progress bar; useful for development but not in production.",
    ),
    threads: int = 4,
    jar_path: Path = JAR_DEFAULT,
    verbose: bool = False,
    base64url: Optional[str] = None,
):
    hourly_feed_files = FeedStorage(feed_type).get_hour(hour)
    if not hourly_feed_files.valid():
        typer.secho(f"missing: {files_missing_metadata}")
        typer.secho(f"invalid: {files_invalid_metadata}")
        raise RuntimeError(
            f"too many files have missing/invalid metadata; {total - len(files)} of {total}"  # noqa: E702
        )

    rt_aggs: Dict[Tuple[pendulum.DateTime, str], List[GTFSRTFeedExtract]] = defaultdict(
        list
    )

    for file in hourly_feed_files.files:
        rt_aggs[(file.hour, file.base64_url)].append(file)

    aggregations_to_process = [
        RTHourlyAggregation(
            step=step,
            filename=f"{feed_type}{JSONL_GZIP_EXTENSION}",
            first_extract=entries[0],
            extracts=entries,
        )
        for (hour, base64url), entries in rt_aggs.items()
    ]

    typer.secho(
        f"found {len(hourly_feed_files.files)} {feed_type} files in {len(aggregations_to_process)} aggregations to process",
        fg=typer.colors.MAGENTA,
    )

    if base64url:
        typer.secho(
            f"url filter applied, only processing {base64url}", fg=typer.colors.YELLOW
        )
        aggregations_to_process = [
            agg for agg in aggregations_to_process if agg.base64_url == base64url
        ]

    if limit:
        typer.secho(f"limit of {limit} feeds was set", fg=typer.colors.YELLOW)
        aggregations_to_process = list(
            sorted(aggregations_to_process, key=lambda feed: feed.path)
        )[:limit]

    aggregated_total = sum(len(agg.extracts) for agg in aggregations_to_process)
    pbar = tqdm(total=len(aggregations_to_process)) if progress else None

    outcomes: List[RTFileProcessingOutcome] = [
        RTFileProcessingOutcome(
            step=step.value,
            success=False,
            blob_path=blob.path,
            exception=MissingMetadata(),
        )
        for blob in hourly_feed_files.files_missing_metadata
    ] + [
        RTFileProcessingOutcome(
            step=step.value,
            success=False,
            blob_path=blob.path,
            exception=InvalidMetadata(),
        )
        for blob in hourly_feed_files.files_invalid_metadata
    ]
    exceptions = []

    # from https://stackoverflow.com/a/55149491
    # could be cleaned up a bit with a namedtuple

    # gcfs does not seem to play nicely with multiprocessing right now, so use threads :(
    # https://github.com/fsspec/gcsfs/issues/379

    with ThreadPoolExecutor(max_workers=threads) as pool:
        futures: Dict[Future, RTHourlyAggregation] = {
            pool.submit(
                parse_and_validate,
                hour=hour,
                jar_path=jar_path,
                verbose=verbose,
                pbar=pbar,
            ): hour
            for hour in aggregations_to_process
        }

        for future in concurrent.futures.as_completed(futures):
            hour = futures[future]
            if pbar:
                pbar.update(1)
            try:
                outcomes.extend(future.result())
            except KeyboardInterrupt:
                raise
            except Exception as e:
                log(
                    f"WARNING: exception {type(e)} {str(e)} bubbled up to top for {hour.path}\n{traceback.format_exc()}",
                    err=True,
                    fg=typer.colors.RED,
                    pbar=pbar,
                )
                sentry_sdk.capture_exception(e)
                exceptions.append((e, hour.path, traceback.format_exc()))

    if pbar:
        del pbar

    if aggregations_to_process:
        result = GTFSRTJobResult(
            # TODO: these seem weird...
            hour=aggregations_to_process[0].hour,
            filename=aggregations_to_process[0].filename.removesuffix(".gz"),
            step=step,
            feed_type=feed_type,
            outcomes=outcomes,
        )
        save_job_result(get_fs(), result)

    assert (
        len(outcomes) == aggregated_total
    ), f"we ended up with {len(outcomes)} outcomes from {aggregated_total}"

    if exceptions:
        exc_str = "\n".join(str(tup) for tup in exceptions)
        msg = f"got {len(exceptions)} exceptions from processing {len(aggregations_to_process)} feeds:\n{exc_str}"  # noqa: E231
        typer.secho(msg, err=True, fg=typer.colors.RED)
        raise RuntimeError(msg)

    typer.secho("fin.", fg=typer.colors.MAGENTA)
    sentry_sdk.flush()


if __name__ == "__main__":
    app()
