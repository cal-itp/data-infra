"""
Parses binary RT feeds and writes them back to GCS as gzipped newline-delimited JSON
"""
import concurrent.futures
import copy
import datetime
import gzip
import hashlib
import json
import os
import subprocess
import tempfile
import traceback
from collections import defaultdict
from concurrent.futures import ThreadPoolExecutor, Future
from enum import Enum
from pathlib import Path
from typing import ClassVar, Dict, List, Optional, Sequence, Tuple, Type, Union
from zipfile import ZipFile

import backoff  # type: ignore
import pendulum
import typer
from aiohttp.client_exceptions import (
    ClientOSError,
    ClientResponseError,
    ServerDisconnectedError,
)
from calitp.storage import (
    GTFSFeedExtractInfo,
    GTFSFeedType,
    GTFSRTFeedExtract,
    PartitionedGCSArtifact,
    ProcessingOutcome,
    fetch_all_in_partition,
    get_fs,
    JSONL_GZIP_EXTENSION,
)  # type: ignore
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


class RTProcessingStep(str, Enum):
    parse = "parse"
    validate = "validate"


def log(*args, err=False, fg=None, pbar=None, **kwargs):
    # capture fg so we don't pass it to pbar
    if pbar:
        pbar.write(*args, **kwargs)
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


class ScheduleDataNotFound(Exception):
    pass


def remove_from_list_if_type(key: str, typ: Type):
    def handler(records):
        for record in records:
            if isinstance(record, typ):
                del record[key]

    return handler


class RTHourlyAggregation(PartitionedGCSArtifact):
    step: RTProcessingStep
    feed_type: GTFSFeedType
    extracts: List[GTFSRTFeedExtract]
    hour: pendulum.DateTime
    base64_url: str
    partition_names: ClassVar[List[str]] = ["dt", "hour", "base64_url"]

    class Config:
        json_encoders = {
            List: remove_from_list_if_type("config", GTFSRTFeedExtract),
        }

    @property
    def bucket(self) -> str:
        if self.step == RTProcessingStep.parse:
            return RT_PARSED_BUCKET
        if self.step == RTProcessingStep.validate:
            return RT_VALIDATION_BUCKET
        raise RuntimeError("we should not be here")

    @validator("extracts", allow_reuse=True)
    def extracts_have_same_hour_and_url(cls, v: List[GTFSRTFeedExtract]):
        hours = set(extract.hour for extract in v)
        urls = set(extract.base64_url for extract in v)
        assert len(hours) == len(urls) == 1
        return v

    @property
    def table(self):
        if self.step == RTProcessingStep.parse:
            return self.feed_type
        if self.step == RTProcessingStep.validate:
            return f"{self.feed_type}_validations"
        raise RuntimeError("we should not be here")

    @property
    def dt(self) -> pendulum.Date:
        return self.hour.date()

    @property
    def unique_filename(self):
        """Used for on-disk handling."""
        return f"{hashlib.md5(self.name.encode('utf-8')).hexdigest()}{JSONL_GZIP_EXTENSION}"


# TODO: this could be merged with the Schedule one
class GTFSRTFeedValidation(PartitionedGCSArtifact):
    bucket: ClassVar[str] = RT_VALIDATION_BUCKET
    partition_names: ClassVar[List[str]] = GTFSRTFeedExtract.partition_names
    extract: GTFSRTFeedExtract = Field(..., exclude={"config"})
    system_errors: Dict

    @property
    def table(self):
        return f"{self.extract.config.data}_validations"

    @property
    def dt(self) -> pendulum.Date:
        return self.extract.ts.date()

    @property
    def base64_url(self) -> str:
        return self.extract.config.base64_encoded_url

    @property
    def ts(self) -> pendulum.DateTime:
        return self.extract.ts


class RTFileValidationOutcome(ProcessingOutcome):
    extract: GTFSRTFeedExtract
    validation: Optional[GTFSRTFeedValidation]


# TODO: this really should encapsulate a lot of hourly aggregations... but do we want to serialize those?
class GTFSRTJobResult(PartitionedGCSArtifact):
    step: RTProcessingStep
    feed_type: GTFSFeedType
    hour: pendulum.DateTime
    partition_names: ClassVar[List[str]] = ["dt", "hour"]
    outcomes: List[RTFileValidationOutcome]

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

    # TODO: I dislike having to exclude the records here
    #   I need to figure out the best way to have a single type represent the "metadata" of
    #   the content as well as the content itself
    def save(self, fs):
        typer.secho(
            f"saving {len(self.outcomes)} outcomes to {self.path}",
            fg=typer.colors.GREEN,
        )
        self.save_content(
            fs=fs,
            content="\n".join(o.json() for o in self.outcomes).encode(),
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
    gtfs_schedule_path: GTFSFeedExtractInfo,
    dst_path: str,
    pbar=None,
) -> Tuple[str, List[str]]:
    # fetch and zip gtfs schedule
    zipname = f"{dst_path[:-1]}.zip"
    log(
        f"Fetching gtfs schedule data from {gtfs_schedule_path} to {zipname}",
        pbar=pbar,
    )

    try:
        get_with_retry(fs, gtfs_schedule_path, dst_path, recursive=True)
    except FileNotFoundError:
        raise ScheduleDataNotFound(f"no schedule data found for {gtfs_schedule_path}")

    # https://github.com/MobilityData/gtfs-realtime-validator/issues/92
    try:
        os.remove(os.path.join(dst_path, "areas.txt"))
    except FileNotFoundError:
        pass

    # this is validation output from validating schedule data, we should remove if it's there
    try:
        os.remove(os.path.join(dst_path, "validation.json"))
    except FileNotFoundError:
        pass

    # TODO: sometimes, feeds can live in a subdirectory within the zipfile
    #       see https://github.com/cal-itp/data-infra/issues/1185 as an
    #       example; ignoring for now
    written = []
    with ZipFile(zipname, "w") as zf:
        for file in os.listdir(dst_path):
            full_path = os.path.join(dst_path, file)
            if not os.path.isfile(full_path):
                continue
            with open(full_path) as f:
                zf.writestr(file, f.read())
            written.append(file)

    if not written:
        raise ScheduleDataNotFound(f"no schedule data found for {gtfs_schedule_path}")

    return zipname, written


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
    ).check_returncode()


class RTFileProcessingOutcome(ProcessingOutcome):
    step: RTProcessingStep
    extract: GTFSRTFeedExtract
    parsed: Optional[RTHourlyAggregation]


def validate_and_upload(
    fs,
    jar_path: Path,
    dst_path_gtfs: str,
    dst_path_rt: str,
    tmp_dir: str,
    hour: RTHourlyAggregation,
    verbose: bool = False,
    pbar=None,
) -> List[RTFileProcessingOutcome]:
    gtfs_zip, included_files = download_gtfs_schedule_zip(
        fs,
        hour.extracts[0].schedule_extract,
        dst_path_gtfs,
        pbar=pbar,
    )

    execute_rt_validator(
        gtfs_zip,
        dst_path_rt,
        jar_path=jar_path,
        verbose=verbose,
        pbar=pbar,
    )

    records_to_upload = []
    outcomes = []
    for extract in hour.extracts:
        results_path = os.path.join(
            dst_path_rt, extract.timestamped_filename + ".results.json"
        )
        try:
            with open(results_path) as f:
                records = json.load(f)
        except FileNotFoundError as e:
            msg = f"WARNING: no validation output file found in {results_path}"
            if verbose:
                log(
                    msg,
                    fg=typer.colors.YELLOW,
                    pbar=pbar,
                )
            outcomes.append(
                RTFileProcessingOutcome(
                    success=False,
                    exception=e,
                    extract=extract,
                )
            )
            continue

        records_to_upload.extend(
            [
                {
                    # back and forth so we can use pydantic serialization
                    "metadata": json.loads(extract.json()),
                    **record,
                }
                for record in records
            ]
        )

        outcomes.append(
            RTFileProcessingOutcome(
                step="validate",
                success=True,
                n_output_records=len(records_to_upload),
                file=extract,
                hive_path=hour.validation_hive_path,
            )
        )

    upload_if_records(
        fs,
        tmp_dir,
        out_path=hour.validation_hive_path,
        records=records_to_upload,
        pbar=pbar,
        verbose=verbose,
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
                        step="parse",
                        success=False,
                        exception=e,
                        file=extract,
                    )
                )
                continue

            if not parsed or "entity" not in parsed:
                msg = f"WARNING: no parsed entity found in {str(extract.path)}"
                if verbose:
                    log(
                        msg,
                        fg=typer.colors.YELLOW,
                        pbar=pbar,
                    )
                outcomes.append(
                    RTFileProcessingOutcome(
                        step="parse",
                        success=False,
                        exception=ValueError(msg),
                        extract=extract,
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
                                "metadata": json.loads(extract.json()),
                                **copy.deepcopy(record),
                            }
                        )
                        + "\n"
                    ).encode("utf-8")
                )
                written += 1
            outcomes.append(
                RTFileProcessingOutcome(
                    step="parse",
                    success=True,
                    extract=extract,
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
    tmp_dir: str,
    verbose: bool = False,
    pbar=None,
) -> List[RTFileProcessingOutcome]:
    fs = get_fs()
    dst_path_gtfs = f"{tmp_dir}/gtfs_{hash(hour.name)}/"
    os.mkdir(dst_path_gtfs)
    dst_path_rt = f"{tmp_dir}/rt_{hash(hour.name)}/"
    get_with_retry(
        fs,
        rpath=[file.path for file in hour.extracts],
        lpath=[
            os.path.join(dst_path_rt, file.timestamped_filename)
            for file in hour.extracts
        ],
    )

    if hour.step == RTProcessingStep.validate:
        try:
            outcomes = validate_and_upload(
                fs=fs,
                jar_path=jar_path,
                dst_path_gtfs=dst_path_gtfs,
                dst_path_rt=dst_path_rt,
                tmp_dir=tmp_dir,
                hour=hour,
                verbose=verbose,
                pbar=pbar,
            )
        except (ScheduleDataNotFound, subprocess.CalledProcessError) as e:
            if verbose:
                log(
                    f"{str(e)} thrown for {hour.extracts[0].schedule_path}",
                    fg=typer.colors.RED,
                    pbar=pbar,
                )

            outcomes = [
                RTFileProcessingOutcome(
                    step="validate",
                    success=False,
                    file=file,
                    exception=e,
                    hive_path=hour.data_hive_path,
                )
                for file in hour.extracts
            ]
        assert len(outcomes) == len(hour.extracts)
        upload_if_records(
            fs,
            tmp_dir,
            out_path=hour.validation_outcomes_hive_path,
            records=outcomes,
            pbar=pbar,
            verbose=verbose,
        )

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
):
    pendulum_hour = pendulum.instance(hour)
    files: List[GTFSRTFeedExtract] = fetch_all_in_partition(
        cls=GTFSRTFeedExtract,
        fs=get_fs(),
        partitions={
            "dt": pendulum_hour.date(),
            "hour": pendulum_hour,
        },
        table=feed_type,
        verbose=True,
        progress=progress,
    )

    typer.secho(
        f"found {len(files)} {feed_type} files to process", fg=typer.colors.MAGENTA
    )

    rt_aggs: Dict[Tuple[pendulum.DateTime, str], List[GTFSRTFeedExtract]] = defaultdict(
        list
    )

    for file in files:
        rt_aggs[(file.hour, file.base64_url)].append(file)

    aggregations_to_process = [
        RTHourlyAggregation(
            step=step,
            filename=f"{feed_type}{JSONL_GZIP_EXTENSION}",
            feed_type=feed_type,
            hour=hour,
            base64_url=url,
            extracts=files,
        )
        for (hour, url), files in rt_aggs.items()
    ]

    if limit:
        typer.secho(f"limit of {limit} feeds was set", fg=typer.colors.YELLOW)
        aggregations_to_process = list(
            sorted(aggregations_to_process, key=lambda feed: feed.path)
        )[:limit]

    pbar = tqdm(total=len(aggregations_to_process)) if progress else None

    outcomes = []
    exceptions = []

    # from https://stackoverflow.com/a/55149491
    # could be cleaned up a bit with a namedtuple

    # gcfs does not seem to play nicely with multiprocessing right now, so use threads :(
    # https://github.com/fsspec/gcsfs/issues/379

    with tempfile.TemporaryDirectory() as tmp_dir:
        with ThreadPoolExecutor(max_workers=threads) as pool:
            futures: Dict[Future, RTHourlyAggregation] = {
                pool.submit(
                    parse_and_validate,
                    hour=hour,
                    jar_path=jar_path,
                    tmp_dir=tmp_dir,
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
                        f"WARNING: exception {type(e)} {str(e)} bubbled up to top for {hour.path}",
                        err=True,
                        fg=typer.colors.RED,
                        pbar=pbar,
                    )
                    exceptions.append((e, hour.path, traceback.format_exc()))

    if pbar:
        del pbar

    assert len(outcomes) == sum(len(hour.extracts) for hour in aggregations_to_process)
    result = GTFSRTJobResult(
        # TODO: these seem weird...
        hour=aggregations_to_process[0].hour,
        filename=aggregations_to_process[0].filename.removesuffix(".gz"),
        step=step,
        feed_type=feed_type,
        outcomes=outcomes,
    )
    result.save(get_fs())

    if exceptions:
        exc_str = "\n".join(str(tup) for tup in exceptions)
        msg = f"got {len(exceptions)} exceptions from processing {len(aggregations_to_process)} feeds:\n{exc_str}"
        typer.secho(msg, err=True, fg=typer.colors.RED)
        raise RuntimeError(msg)

    typer.secho("fin.", fg=typer.colors.MAGENTA)


if __name__ == "__main__":
    typer.run(main)
