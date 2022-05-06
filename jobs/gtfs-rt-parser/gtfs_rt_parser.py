"""
Parses binary RT feeds and writes them back to GCS as gzipped newline-delimited JSON
"""
import concurrent.futures
import copy
import gzip
import hashlib
import json
import os
import subprocess
import tempfile
import traceback
from collections import defaultdict
from concurrent.futures import ThreadPoolExecutor
from enum import Enum
from functools import lru_cache
from pathlib import Path
from typing import List, Optional, Dict, Union, Tuple
from zipfile import ZipFile

import backoff
import pendulum
import typer
from aiohttp.client_exceptions import ClientResponseError, ClientOSError
from calitp.config import get_bucket
from calitp.storage import get_fs
from google.protobuf import json_format
from google.protobuf.message import DecodeError
from google.transit import gtfs_realtime_pb2
from pydantic import BaseModel, validator
from tqdm import tqdm

# Note that all RT extraction is stored in the prod bucket, since it is very large,
# but we can still output processed results to the staging bucket

JSONL_GZIP_EXTENSION = ".jsonl.gz"

RT_VALIDATOR_JAR_LOCATION_ENV_KEY = "GTFS_RT_VALIDATOR_JAR"
JAR_DEFAULT = typer.Option(
    os.environ.get(RT_VALIDATOR_JAR_LOCATION_ENV_KEY),
    help="Path to the GTFS RT Validator JAR",
)


def log(*args, err=False, fg=None, pbar=None, **kwargs):
    # capture fg so we don't pass it to pbar
    if pbar:
        pbar.write(*args, **kwargs)
    else:
        typer.secho(*args, err=err, fg=fg, **kwargs)


def upload_if_records(
    fs,
    tmp_dir,
    out_path,
    records: Union[List[Dict], List[BaseModel]],
    pbar=None,
    verbose=False,
):
    log(
        f"writing {len(records)} lines to {out_path}",
        pbar=pbar,
    )
    with tempfile.NamedTemporaryFile(mode="wb", delete=False, dir=tmp_dir) as f:
        gzipfile = gzip.GzipFile(mode="wb", fileobj=f)
        if records:
            if isinstance(records[0], BaseModel):
                encoded = (r.json() for r in records)
            else:
                encoded = (json.dumps(r) for r in records)
            gzipfile.write("\n".join(encoded).encode("utf-8"))
        else:
            # BigQuery fails when trying to parse empty files, so we include a single newline character
            gzipfile.write("\n".encode("utf-8"))
        gzipfile.close()

    put_with_retry(fs, f.name, out_path)


class ScheduleDataNotFound(Exception):
    pass


class RTFileType(str, Enum):
    service_alerts = "service_alerts"
    trip_updates = "trip_updates"
    vehicle_positions = "vehicle_positions"


class RTFile(BaseModel):
    file_type: RTFileType
    path: Path
    itp_id: int
    url: int
    tick: pendulum.DateTime

    class Config:
        json_encoders = {
            Path: lambda p: str(p),
        }

    @property
    def timestamped_filename(self):
        return str(self.path.name) + self.tick.strftime("__%Y-%m-%dT%H:%M:%SZ")

    @property
    def schedule_path(self):
        return os.path.join(
            get_bucket(),
            "schedule",
            str(self.tick.replace(hour=0, minute=0, second=0)),
            f"{self.itp_id}_{self.url}",
        )

    @property
    def hive_partitions(self) -> Tuple[str, str, str, str, str]:
        return (
            f"dt={self.tick.to_date_string()}",
            f"itp_id={self.itp_id}",
            f"url_number={self.url}",
            f"hour={self.tick.hour}",
            f"{self.path.name}{JSONL_GZIP_EXTENSION}",
        )

    def data_hive_path(self, bucket: str):
        return os.path.join(
            bucket,
            self.file_type,
            *self.hive_partitions,
        )

    def validation_hive_path(self, bucket: str):
        return os.path.join(
            bucket,
            f"{self.file_type}_validations",
            *self.hive_partitions,
        )

    def outcomes_hive_path(self, bucket: str):
        return os.path.join(
            bucket,
            f"{self.file_type}_outcomes",
            *self.hive_partitions,
        )

    def validation_outcomes_hive_path(self, bucket: str):
        return os.path.join(
            bucket,
            f"{self.file_type}_validations_outcomes",
            *self.hive_partitions,
        )


class RTHourlyAggregation(BaseModel):
    data_hive_path: str
    validation_hive_path: str
    outcomes_hive_path: str
    validation_outcomes_hive_path: str
    source_files: List[RTFile]

    @property
    def suffix(self) -> str:
        return hashlib.md5(self.data_hive_path.encode("utf-8")).hexdigest()


class RTFileProcessingOutcome(BaseModel):
    step: str
    success: bool
    file: RTFile
    n_output_records: Optional[int]
    exception: Optional[Exception]
    hive_path: Optional[str]
    body: Optional[str]

    class Config:
        arbitrary_types_allowed = True
        json_encoders = {Exception: lambda e: str(e)}

    @validator("step")
    def step_must_be_parse_or_validate(cls, v):
        assert v in ("parse", "validate"), "step must be parse or validate"
        return v

    # this is annoying, waiting on https://github.com/samuelcolvin/pydantic/pull/2625
    @validator("exception")
    def exception_existence_matches_success(cls, v, values):
        assert values["success"] == (v is None), "if success, exception must be None"
        return v


def fatal_code(e):
    return isinstance(e, ClientResponseError) and e.status == 404


@backoff.on_exception(
    backoff.expo,
    exception=(ClientOSError, ClientResponseError),
    max_tries=3,
    giveup=fatal_code,
)
def get_with_retry(fs, *args, **kwargs):
    return fs.get(*args, **kwargs)


@backoff.on_exception(
    backoff.expo, exception=(ClientOSError, ClientResponseError), max_tries=3
)
def put_with_retry(fs, *args, **kwargs):
    return fs.put(*args, **kwargs)


@lru_cache(maxsize=None)
def identify_files(glob, rt_file_type: RTFileType, progress=False) -> List[RTFile]:
    fs = get_fs()
    typer.secho("Globbing rt bucket {}".format(glob), fg=typer.colors.MAGENTA)

    before = pendulum.now()
    ticks = fs.glob(glob)
    typer.echo(
        f"globbing {len(ticks)} ticks took {(pendulum.now() - before).in_words(locale='en')}"
    )

    files = []
    if progress:
        ticks = tqdm(ticks, desc="")
    for tick in ticks:
        tick_dt = pendulum.parse(Path(tick).name)  # I love this
        files_in_tick = [
            filename for filename in fs.ls(tick) if rt_file_type.name in filename
        ]

        for fname in files_in_tick:
            # This is bad
            itp_id, url = fname.split("/")[-3:-1]
            files.append(
                RTFile(
                    file_type=rt_file_type,
                    path=fname,
                    itp_id=itp_id,
                    url=url,
                    tick=tick_dt,
                )
            )

    # for some reason the fs.glob command takes up a fair amount of memory here,
    # and does not seem to free it after the function returns, so we manually clear
    # its caches (at least the ones I could find)
    fs.dircache.clear()

    typer.secho(
        f"found {len(files)} {rt_file_type} files in glob {glob}", fg=typer.colors.GREEN
    )
    return files


def download_gtfs_schedule_zip(
    fs, gtfs_schedule_path, dst_path, pbar=None
) -> (str, List[str]):
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


def validate_and_upload(
    fs,
    jar_path: Path,
    dst_path_gtfs,
    dst_path_rt,
    tmp_dir,
    hour: RTHourlyAggregation,
    verbose=False,
    pbar=None,
) -> List[RTFileProcessingOutcome]:
    gtfs_zip, included_files = download_gtfs_schedule_zip(
        fs,
        hour.source_files[0].schedule_path,
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
    for rt_file in hour.source_files:
        results_path = os.path.join(
            dst_path_rt, rt_file.timestamped_filename + ".results.json"
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
                    step="validate",
                    success=False,
                    exception=e,
                    file=rt_file,
                    hive_path=hour.validation_hive_path,
                    body=msg,
                )
            )
            continue

        records_to_upload.extend(
            [
                {
                    # back and forth so we can use pydantic serialization
                    "metadata": json.loads(rt_file.json()),
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
                file=rt_file,
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
    gzip_fname = str(tmp_dir + f"/data_{hour.suffix}" + JSONL_GZIP_EXTENSION)

    # ParseFromString() seems to not release memory well, so manually handle
    # writing to the gzip and cleaning up after ourselves

    with gzip.open(gzip_fname, "w") as gzipfile:
        for rt_file in hour.source_files:
            feed = gtfs_realtime_pb2.FeedMessage()

            try:
                with open(
                    os.path.join(dst_path_rt, rt_file.timestamped_filename), "rb"
                ) as f:
                    feed.ParseFromString(f.read())
                parsed = json_format.MessageToDict(feed)
            except DecodeError as e:
                if verbose:
                    log(
                        f"WARNING: DecodeError for {str(rt_file.path)}",
                        fg=typer.colors.YELLOW,
                        pbar=pbar,
                    )
                outcomes.append(
                    RTFileProcessingOutcome(
                        step="parse",
                        success=False,
                        exception=e,
                        file=rt_file,
                    )
                )
                continue

            if not parsed or "entity" not in parsed:
                msg = f"WARNING: no records found in {str(rt_file.path)}"
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
                        file=rt_file,
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
                                "metadata": json.loads(rt_file.json()),
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
                    file=rt_file,
                    n_output_records=len(parsed["entity"]),
                    hive_path=hour.data_hive_path,
                )
            )
            del parsed

    if written:
        log(
            f"writing {written} lines to {hour.data_hive_path}",
            pbar=pbar,
        )
        put_with_retry(fs, gzip_fname, f"{hour.data_hive_path}")
    else:
        log(
            f"WARNING: no records at all for {hour.data_hive_path}",
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
    parse: bool = False,
    validate: bool = False,
    pbar=None,
):
    if not parse and not validate:
        raise ValueError("skipping both parsing and validation does nothing for us!")

    fs = get_fs()
    suffix = hour.suffix
    dst_path_gtfs = f"{tmp_dir}/gtfs_{suffix}/"
    os.mkdir(dst_path_gtfs)
    dst_path_rt = f"{tmp_dir}/rt_{suffix}/"
    get_with_retry(
        fs,
        rpath=[file.path for file in hour.source_files],
        lpath=[
            os.path.join(dst_path_rt, file.timestamped_filename)
            for file in hour.source_files
        ],
    )

    if validate:
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
                    f"{str(e)} thrown for {hour.source_files[0].schedule_path}",
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
                for file in hour.source_files
            ]
        assert len(outcomes) == len(hour.source_files)
        upload_if_records(
            fs,
            tmp_dir,
            out_path=hour.validation_outcomes_hive_path,
            records=outcomes,
            pbar=pbar,
            verbose=verbose,
        )

    if parse:
        outcomes = parse_and_upload(
            fs=fs,
            dst_path_rt=dst_path_rt,
            tmp_dir=tmp_dir,
            hour=hour,
            verbose=verbose,
            pbar=pbar,
        )
        assert len(outcomes) == len(hour.source_files)
        upload_if_records(
            fs,
            tmp_dir,
            out_path=hour.outcomes_hive_path,
            records=outcomes,
            pbar=pbar,
            verbose=verbose,
        )


def main(
    file_type: RTFileType,
    glob: str,
    dst_bucket: str,
    limit: int = 0,
    parse: bool = False,
    validate: bool = False,
    progress: bool = typer.Option(
        False,
        help="If true, display progress bar; useful for development but not in production.",
    ),
    verbose: bool = False,
    threads: int = 4,
    jar_path: Path = JAR_DEFAULT,
):
    assert parse ^ validate, "must either parse xor validate"

    typer.secho(f"processing {file_type} from {glob}", fg=typer.colors.MAGENTA)

    # fetch files ----
    files = identify_files(glob=glob, rt_file_type=file_type, progress=progress)

    feed_hours = defaultdict(list)

    for file in files:
        feed_hours[file.hive_partitions].append(file)

    typer.secho(
        f"found {len(feed_hours)} feed-hours to process", fg=typer.colors.MAGENTA
    )

    feed_hours = [
        RTHourlyAggregation(
            data_hive_path=files[0].data_hive_path(dst_bucket),
            # this is a bit weird
            validation_hive_path=files[0].validation_hive_path(dst_bucket),
            outcomes_hive_path=files[0].outcomes_hive_path(dst_bucket),
            validation_outcomes_hive_path=files[0].validation_outcomes_hive_path(
                dst_bucket
            ),
            source_files=files,
        )
        for hive_path, files in feed_hours.items()
    ]

    if limit:
        typer.secho(f"limit of {limit} feeds was set", fg=typer.colors.YELLOW)
        feed_hours = list(sorted(feed_hours, key=lambda feed: feed.data_hive_path))[
            :limit
        ]

    pbar = tqdm(total=len(feed_hours)) if progress else None

    exceptions = []

    # from https://stackoverflow.com/a/55149491
    # could be cleaned up a bit with a namedtuple

    # gcfs does not seem to play nicely with multiprocessing right now, so use threads :(
    # https://github.com/fsspec/gcsfs/issues/379

    with tempfile.TemporaryDirectory() as tmp_dir:
        with ThreadPoolExecutor(max_workers=threads) as pool:
            futures = {
                pool.submit(
                    parse_and_validate,
                    hour=hour,
                    jar_path=jar_path,
                    tmp_dir=tmp_dir,
                    verbose=verbose,
                    parse=parse,
                    validate=validate,
                    pbar=pbar,
                ): hour
                for hour in feed_hours
            }

            for future in concurrent.futures.as_completed(futures):
                hour = futures[future]
                if pbar:
                    pbar.update(1)
                try:
                    future.result()
                except KeyboardInterrupt:
                    raise
                except Exception as e:
                    log(
                        f"WARNING: exception {type(e)} {str(e)} bubbled up to top for {hour.data_hive_path}",
                        err=True,
                        fg=typer.colors.RED,
                        pbar=pbar,
                    )
                    exceptions.append((e, hour.data_hive_path, traceback.format_exc()))

    if pbar:
        del pbar

    if exceptions:
        exc_str = "\n".join(str(tup) for tup in exceptions)
        msg = f"got {len(exceptions)} exceptions from processing {len(feed_hours)} feeds:\n{exc_str}"
        typer.secho(msg, err=True, fg=typer.colors.RED)
        raise RuntimeError(msg)

    typer.secho("fin.", fg=typer.colors.MAGENTA)


if __name__ == "__main__":
    typer.run(main)
