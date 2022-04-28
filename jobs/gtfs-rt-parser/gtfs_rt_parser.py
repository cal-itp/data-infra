"""
Parses binary RT feeds and writes them back to GCS as gzipped newline-delimited JSON
"""
import concurrent.futures
import gzip
import json
import os
import shutil
import subprocess
import tempfile
from collections import defaultdict
from concurrent.futures import ThreadPoolExecutor
from datetime import timedelta, date
from enum import Enum
from functools import lru_cache
from pathlib import Path
from typing import List

import backoff
import pendulum
import typer
from aiohttp.client_exceptions import ClientResponseError
from calitp.config import get_bucket
from calitp.storage import get_fs
from google.protobuf import json_format
from google.protobuf.message import DecodeError
from google.transit import gtfs_realtime_pb2
from pydantic import BaseModel
from ratelimit import RateLimitException, limits
from tqdm import tqdm

# Note that all RT extraction is stored in the prod bucket, since it is very large,
# but we can still output processed results to the staging bucket

JSONL_GZIP_EXTENSION = ".jsonl.gz"

RT_VALIDATOR_JAR_LOCATION_ENV_KEY = "GTFS_RT_VALIDATOR_JAR"
JAR_DEFAULT = typer.Option(
    os.environ.get(RT_VALIDATOR_JAR_LOCATION_ENV_KEY),
    help="Path to the GTFS RT Validator JAR",
)

yesterday = (date.today() - timedelta(days=1)).isoformat()


def log(*args, err=False, fg=None, pbar=None, **kwargs):
    # capture fg so we don't pass it to pbar
    if pbar:
        pbar.write(*args, **kwargs)
    else:
        typer.secho(*args, err=err, fg=fg, **kwargs)


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


class RTAggregation(BaseModel):
    hive_path: str
    validation_hive_path: str
    source_files: List[RTFile]


@backoff.on_exception(backoff.expo, exception=ClientResponseError, max_tries=3)
@backoff.on_exception(backoff.expo, exception=RateLimitException)
@limits(calls=1, period=1)
def get_with_retry(fs, *args, **kwargs):
    return fs.get(*args, **kwargs)


@backoff.on_exception(backoff.expo, exception=ClientResponseError, max_tries=3)
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


def download_gtfs_schedule_zip(gtfs_schedule_path, dst_path, fs, pbar=None):
    # fetch and zip gtfs schedule
    log(
        f"Fetching gtfs schedule data from {gtfs_schedule_path} to {dst_path}",
        pbar=pbar,
    )

    try:
        get_with_retry(fs, gtfs_schedule_path, dst_path, recursive=True)
    except FileNotFoundError as e:
        log(
            f"WARNING: got {type(e)} trying to download {gtfs_schedule_path}", pbar=pbar
        )
        raise ScheduleDataNotFound from e

    try:
        os.remove(os.path.join(dst_path, "areas.txt"))
    except FileNotFoundError:
        pass

    return shutil.make_archive(dst_path, "zip", dst_path)


def execute_rt_validator(
    gtfs_file: str, rt_path: str, jar_path: Path, verbose=False, pbar=None
):
    log(f"validating {rt_path} with {gtfs_file}", fg=typer.colors.MAGENTA, pbar=pbar)

    # We probably should always print stderr?
    stderr = subprocess.DEVNULL if not verbose else None
    stdout = subprocess.DEVNULL if not verbose else None

    subprocess.check_call(
        [
            "java",
            "-jar",
            str(jar_path),
            "-gtfs",
            gtfs_file,
            "-gtfsRealtimePath",
            rt_path,
            "-sort",
            "name",
        ],
        stderr=stderr,
        stdout=stdout,
    )


# Originally this whole function was retried, but tmpdir flakiness will throw
# exceptions in backoff's context, which ruins things
def parse_and_aggregate_hour(
    hour: RTAggregation,
    jar_path: Path,
    verbose: bool = False,
    parse: bool = True,
    validate: bool = True,
    pbar=None,
):
    if not parse and not validate:
        raise ValueError("skipping both parsing and validation does nothing for us!")

    fs = get_fs()

    # probably a better way to do this
    out_path = f"{hour.hive_path}{JSONL_GZIP_EXTENSION}"
    validation_out_path = f"{hour.validation_hive_path}{JSONL_GZIP_EXTENSION}"

    with tempfile.TemporaryDirectory() as tmp_dir:
        dst_path_gtfs = f"{tmp_dir}/gtfs"
        dst_path_rt = f"{tmp_dir}/rt"
        get_with_retry(
            fs,
            rpath=[file.path for file in hour.source_files],
            lpath=[
                os.path.join(dst_path_rt, file.timestamped_filename)
                for file in hour.source_files
            ],
        )

        if validate:
            gtfs_zip = download_gtfs_schedule_zip(
                hour.source_files[0].schedule_path,
                dst_path_gtfs,
                fs=fs,
                pbar=pbar,
            )
            execute_rt_validator(
                gtfs_zip,
                dst_path_rt,
                jar_path=jar_path,
                verbose=verbose,
                pbar=pbar,
            )

        gzip_fname = str(tmp_dir + "/data" + JSONL_GZIP_EXTENSION)
        gzip_validation_fname = str(tmp_dir + "/validation" + JSONL_GZIP_EXTENSION)
        written = 0
        validation_written = 0
        with gzip.open(gzip_fname, "w") as gzipfile, gzip.open(
            gzip_validation_fname, "w"
        ) as validation_gzipfile:
            for rt_file in hour.source_files:
                feed = gtfs_realtime_pb2.FeedMessage()

                try:
                    with open(
                        os.path.join(dst_path_rt, rt_file.timestamped_filename), "rb"
                    ) as f:
                        feed.ParseFromString(f.read())
                    parsed = json_format.MessageToDict(feed)
                except DecodeError:
                    log(
                        f"WARN: got DecodeError for {str(rt_file.path)}",
                        fg=typer.colors.YELLOW,
                        pbar=pbar,
                    )
                    continue

                if not parsed or "entity" not in parsed:
                    log(
                        f"WARNING: no records found in {str(rt_file.path)}",
                        fg=typer.colors.YELLOW,
                        pbar=pbar,
                    )
                    continue

                for record in parsed["entity"]:
                    record.update(
                        {
                            "header": parsed["header"],
                            "metadata": json.loads(
                                rt_file.json()
                            ),  # back and forth so we use pydantic serialization
                        }
                    )
                    gzipfile.write((json.dumps(record) + "\n").encode("utf-8"))
                    written += 1

                if validate:
                    with open(
                        os.path.join(
                            dst_path_rt, rt_file.timestamped_filename + ".results.json"
                        )
                    ) as f:
                        records = json.load(f)
                    for record in records:
                        record.update(
                            {
                                "metadata": json.loads(
                                    rt_file.json()
                                ),  # back and forth so we use pydantic serialization
                            }
                        )
                        validation_gzipfile.write(
                            (json.dumps(record) + "\n").encode("utf-8")
                        )
                        validation_written += 1

        if written:
            log(f"writing {written} lines to {out_path}", pbar=pbar)
            put_with_retry(fs, gzip_fname, out_path)
        else:
            log(
                f"WARNING: no records at all for {hour.hive_path}",
                fg=typer.colors.YELLOW,
            )

        if validation_written:
            log(
                f"writing {validation_written} lines to {validation_out_path}",
                pbar=pbar,
            )
            put_with_retry(fs, gzip_validation_fname, validation_out_path)
        else:
            log(
                f"WARNING: no records at all for {hour.hive_path}",
                fg=typer.colors.YELLOW,
                pbar=pbar,
            )


def main(
    file_type: RTFileType,
    glob: str,
    dst_bucket: str,
    limit: int = 0,
    progress: bool = typer.Option(
        False,
        help="If true, display progress bar; useful for development but not in production.",
    ),
    verbose: bool = False,
    threads: int = 4,
    jar_path: Path = JAR_DEFAULT,
):
    typer.secho(f"Parsing {file_type} from {glob}", fg=typer.colors.MAGENTA)

    # fetch files ----
    files = identify_files(glob=glob, rt_file_type=file_type, progress=progress)

    feed_hours = defaultdict(list)

    for file in files:
        feed_hours[file.hive_path(dst_bucket)].append(file)

    feed_hours = [
        RTAggregation(
            hive_path=hive_path,
            # this is a bit weird
            validation_hive_path=files[0].validation_hive_path(dst_bucket),
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

    with ThreadPoolExecutor(max_workers=threads) as pool:
        futures = {
            pool.submit(
                parse_and_aggregate_hour,
                hour=hour,
                jar_path=jar_path,
                verbose=verbose,
                parse=True,
                validate=True,
                pbar=pbar,
            ): hour
            for hour in feed_hours
        }

        for future in concurrent.futures.as_completed(futures):
            hour = futures[future]
            pbar.update(1)
            try:
                future.result()
            except KeyboardInterrupt:
                raise
            except OSError as e:
                # a lot of these are thrown by tmpdir, and are potentially flakes; but if they were thrown during
                # handling of another exception, we want that exception still
                if e.errno == 39:
                    e = e.__cause__ or e.__context__
                exceptions.append((e, hour.hive_path))
            except ScheduleDataNotFound:
                log(
                    f"WARNING: no gtfs schedule data found for {hour.hive_path}",
                    err=True,
                    fg=typer.colors.YELLOW,
                    pbar=pbar,
                )
            except Exception as e:
                log(
                    f"WARNING: got exception {type(e)} for {hour.hive_path}",
                    err=True,
                    fg=typer.colors.RED,
                    pbar=pbar,
                )
                exceptions.append((e, hour.hive_path))

    if exceptions:
        msg = f"got {len(exceptions)} exceptions from processing {len(feed_hours)} feeds: {exceptions}"
        typer.secho(msg, err=True, fg=typer.colors.RED)
        raise RuntimeError(msg)

    typer.secho("fin.", fg=typer.colors.MAGENTA)


if __name__ == "__main__":
    typer.run(main)
