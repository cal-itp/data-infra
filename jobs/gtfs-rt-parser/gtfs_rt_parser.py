"""
Parses binary RT feeds and writes them back to GCS as gzipped newline-delimited JSON
"""
import concurrent.futures
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
from io import BytesIO
from pathlib import Path
from typing import List, Optional, Dict, Union
from zipfile import ZipFile

import backoff
import pendulum
import typer
from aiohttp.client_exceptions import ClientResponseError, ClientOSError
from calitp.config import get_bucket
from calitp.storage import get_fs
from google.api_core.exceptions import NotFound
from google.cloud.storage import Client
from google.protobuf import json_format
from google.protobuf.message import DecodeError
from google.transit import gtfs_realtime_pb2
from pydantic import BaseModel
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


def upload_gzipped_records(
    fs,
    gzip_fname,
    out_path,
    records: Union[List[Dict], List[BaseModel]],
    pbar=None,
    verbose=False,
):
    log(
        f"writing {len(records)} lines to {out_path}",
        pbar=pbar,
    )
    with gzip.open(gzip_fname, "w") as gzipfile:
        if isinstance(records[0], BaseModel):
            encoded = (r.json() for r in records)
        else:
            encoded = (json.dumps(r) for r in records)
        gzipfile.write("\n".join(encoded).encode("utf-8"))
    put_with_retry(fs, gzip_fname, out_path)


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
        return str(self.path.name) + self.tick.strftime("__%Y-%m-%dT%H:%M:%SZ.pb")

    @property
    def schedule_path(self):
        return os.path.join(
            get_bucket(),
            "schedule",
            str(self.tick.replace(hour=0, minute=0, second=0)),
            f"{self.itp_id}_{self.url}",
        )

    def hive_path(self, bucket: str):
        return os.path.join(
            bucket,
            self.file_type,
            f"dt={self.tick.to_date_string()}",
            f"itp_id={self.itp_id}",
            f"url_number={self.url}",
            f"hour={self.tick.hour}",
            self.path.name,
        )

    def validation_hive_path(self, bucket: str):
        return os.path.join(
            bucket,
            f"{self.file_type}_validations",
            f"dt={self.tick.to_date_string()}",
            f"itp_id={self.itp_id}",
            f"url_number={self.url}",
            f"hour={self.tick.hour}",
            self.path.name,
        )

    def errors_hive_path(self, bucket: str):
        return os.path.join(
            bucket,
            f"{self.file_type}_errors",
            f"dt={self.tick.to_date_string()}",
            f"itp_id={self.itp_id}",
            f"url_number={self.url}",
            f"hour={self.tick.hour}",
            self.path.name,
        )


class RTAggregation(BaseModel):
    hive_path: str
    validation_hive_path: str
    errors_hive_path: str
    source_files: List[RTFile]

    @property
    def suffix(self) -> str:
        return hashlib.md5(self.hive_path.encode("utf-8")).hexdigest()


class RTFileProcessingError(BaseModel):
    step: str
    exception: str
    hive_path: Optional[str]
    file: Optional[RTFile]
    body: Optional[str]


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


def download_gtfs_schedule_zip(gtfs_schedule_path, dst_path, pbar=None):
    # fetch and zip gtfs schedule
    zipname = f"{dst_path[:-1]}.zip"
    log(
        f"Fetching gtfs schedule data from {gtfs_schedule_path} to {zipname}",
        pbar=pbar,
    )

    files = [
        "agency.txt",
        "calendar_attributes.txt",
        "fare_capping.txt",
        "fare_products.txt",
        "levels.txt",
        "shapes.txt",
        "transfers.txt",
        "attributions.txt",
        "calendar_dates.txt",
        "fare_containers.txt",
        "fare_transfer_rules.txt",
        "mtc_feed_versions.txt",
        "rider_categories.txt",
        "stop_times.txt",
        "trips.txt",
        "calendar.txt",
        "directions.txt",
        "fare_leg_rules.txt",
        "feed_info.txt",
        "pathways.txt",
        "routes.txt",
        "stops.txt",
    ]

    # Do this manually; gcsfs.get() with recursive=True downloads extra stuff we don't need
    downloaded = []
    client = Client()
    with ZipFile(zipname, "w") as zf:
        for file in files:
            io = BytesIO()
            try:
                client.download_blob_to_file(f"{gtfs_schedule_path}/{file}", io)
                io.seek(0)
                zf.writestr(file, io.read().decode("utf-8"))
                downloaded.append(file)
            except NotFound:
                pass

    if not downloaded:
        raise ScheduleDataNotFound(f"no schedule data found for {gtfs_schedule_path}")

    os.sync()

    with ZipFile(zipname, "r") as zf:
        zipped_fnames = set(map(lambda f: str(Path(f).name), zf.namelist()))
        assert (
            set(downloaded) == zipped_fnames
        ), f"zipfile not successful {dst_path}\n{set(downloaded)}\n!=\n{zipped_fnames}"

    return zipname


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
    hour: RTAggregation,
    verbose=False,
    pbar=None,
) -> List[RTFileProcessingError]:
    validate = True
    errors = []
    try:
        gtfs_zip = download_gtfs_schedule_zip(
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
    except ScheduleDataNotFound as e:
        errors.append(
            RTFileProcessingError(
                step="download_schedule",
                exception=str(e),
                hive_path=hour.hive_path,
            )
        )
        validate = False
    except subprocess.CalledProcessError as e:
        # TODO: do something about this
        log(
            f"WARNING: execute_rt_validator failed for {dst_path_rt} and {gtfs_zip}; includes files {os.listdir(dst_path_gtfs)}",
            fg=typer.colors.RED,
            pbar=pbar,
        )
        errors.append(
            RTFileProcessingError(
                step="validate",
                exception=str(e),
                hive_path=hour.hive_path,
                body=e.stderr,
            )
        )
        validate = False

    if validate:
        for rt_file in hour.source_files:
            try:
                with open(
                    os.path.join(
                        dst_path_rt,
                        rt_file.timestamped_filename + ".results.json",
                    )
                ) as f:
                    records = json.load(f)
            except FileNotFoundError:
                if verbose:
                    log(
                        f"WARNING: no validation output found in {str(rt_file.timestamped_filename)}",
                        fg=typer.colors.YELLOW,
                        pbar=pbar,
                    )
                continue

            for record in records:
                records.append(
                    {
                        # back and forth so we can use pydantic serialization
                        "metadata": json.loads(rt_file.json()),
                        **record,
                    }
                )

    if records:
        upload_gzipped_records(
            fs,
            gzip_fname=str(
                tmp_dir + f"/validation_{hour.suffix}" + JSONL_GZIP_EXTENSION
            ),
            out_path=f"{hour.validation_hive_path}{JSONL_GZIP_EXTENSION}",
            records=records,
            pbar=pbar,
            verbose=verbose,
        )
    else:
        log(
            f"WARNING: no records at all for {hour.validation_hive_path}",
            fg=typer.colors.YELLOW,
            pbar=pbar,
        )

    return errors


def parse_and_upload(
    fs,
    dst_path_rt,
    tmp_dir,
    hour: RTAggregation,
    verbose=False,
    pbar=None,
) -> List[RTFileProcessingError]:
    records = []
    errors = []
    for rt_file in hour.source_files:
        feed = gtfs_realtime_pb2.FeedMessage()

        try:
            with open(
                os.path.join(dst_path_rt, rt_file.timestamped_filename), "rb"
            ) as f:
                feed.ParseFromString(f.read())
            parsed = json_format.MessageToDict(feed)
        except DecodeError as e:
            errors.append(
                RTFileProcessingError(
                    step="parse",
                    exception=str(e),
                    file=rt_file,
                )
            )
            continue

        if not parsed or "entity" not in parsed:
            if verbose:
                log(
                    f"WARNING: no records found in {str(rt_file.path)}",
                    fg=typer.colors.YELLOW,
                    pbar=pbar,
                )
            continue

        for record in parsed["entity"]:
            records.append(
                {
                    "header": parsed["header"],
                    # back and forth so we use pydantic serialization
                    "metadata": json.loads(rt_file.json()),
                    **record,
                }
            )
    if records:
        upload_gzipped_records(
            fs,
            gzip_fname=str(tmp_dir + f"/data_{hour.suffix}" + JSONL_GZIP_EXTENSION),
            out_path=f"{hour.hive_path}{JSONL_GZIP_EXTENSION}",
            records=records,
            pbar=pbar,
            verbose=verbose,
        )
    else:
        log(
            f"WARNING: no records at all for {hour.hive_path}",
            fg=typer.colors.YELLOW,
            pbar=pbar,
        )

    return errors


# Originally this whole function was retried, but tmpdir flakiness will throw
# exceptions in backoff's context, which ruins things
def parse_and_aggregate_hour(
    hour: RTAggregation,
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

    errors: List[RTFileProcessingError] = []

    if validate:
        errors.extend(
            validate_and_upload(
                fs=fs,
                jar_path=jar_path,
                dst_path_gtfs=dst_path_gtfs,
                dst_path_rt=dst_path_rt,
                tmp_dir=tmp_dir,
                hour=hour,
                verbose=verbose,
                pbar=pbar,
            )
        )

    if parse:
        errors.extend(
            parse_and_upload(
                fs,
                dst_path_rt,
                tmp_dir,
                hour,
                verbose,
                pbar,
            )
        )

    if errors:
        upload_gzipped_records(
            fs,
            gzip_fname=str(tmp_dir + f"/errors_{hour.suffix}" + JSONL_GZIP_EXTENSION),
            out_path=f"{hour.errors_hive_path}{JSONL_GZIP_EXTENSION}",
            records=errors,
            pbar=pbar,
            verbose=verbose,
        )
    else:
        log(
            f"WARNING: no records at all for {hour.errors_hive_path}",
            fg=typer.colors.YELLOW,
            pbar=pbar,
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
        feed_hours[file.hive_path(dst_bucket)].append(file)

    typer.secho(
        f"found {len(feed_hours)} feed-hours to process", fg=typer.colors.MAGENTA
    )

    feed_hours = [
        RTAggregation(
            hive_path=hive_path,
            # this is a bit weird
            validation_hive_path=files[0].validation_hive_path(dst_bucket),
            errors_hive_path=files[0].errors_hive_path(dst_bucket),
            source_files=files,
        )
        for hive_path, files in feed_hours.items()
    ]

    if limit:
        typer.secho(f"limit of {limit} feeds was set", fg=typer.colors.YELLOW)
        feed_hours = list(sorted(feed_hours, key=lambda feed: feed.hive_path))[:limit]

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
                    parse_and_aggregate_hour,
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
                except ScheduleDataNotFound:
                    log(
                        f"WARNING: no gtfs schedule data found for {hour.hive_path}",
                        err=True,
                        fg=typer.colors.YELLOW,
                        pbar=pbar,
                    )
                except Exception as e:
                    log(
                        f"WARNING: exception {str(e)} bubbled up to top for {hour.hive_path}",
                        err=True,
                        fg=typer.colors.RED,
                        pbar=pbar,
                    )
                    exceptions.append((e, hour.hive_path, traceback.format_exc()))

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
