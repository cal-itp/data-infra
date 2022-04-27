"""
Parses binary RT feeds and writes them back to GCS as gzipped newline-delimited JSON
"""
import gzip
import json
import os
import tempfile
import traceback
from collections import defaultdict
from concurrent.futures import ThreadPoolExecutor
from datetime import timedelta, date
from enum import Enum
from pathlib import Path
from typing import Optional, List

import backoff
import pendulum
import structlog
import typer
from aiohttp.client_exceptions import ClientResponseError
from calitp.storage import get_fs
from google.protobuf import json_format
from google.protobuf.message import DecodeError
from google.transit import gtfs_realtime_pb2
from pydantic import BaseModel
from tqdm import tqdm

# Note that all RT extraction is stored in the prod bucket, since it is very large,
# but we can still output processed results to the staging bucket

EXTENSION = ".jsonl.gz"

yesterday = (date.today() - timedelta(days=1)).isoformat()


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


class RTAggregation(BaseModel):
    hive_path: str
    source_files: List[RTFile]


# Try twice in the event we get a ClientResponseError; doesn't have much of a delay (like 0.01s)
@backoff.on_exception(backoff.expo, exception=ClientResponseError, max_tries=3)
def get_with_retry(fs, *args, **kwargs):
    return fs.get(*args, **kwargs)


@backoff.on_exception(backoff.expo, exception=ClientResponseError, max_tries=3)
def put_with_retry(fs, *args, **kwargs):
    return fs.put(*args, **kwargs)


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

    typer.secho(f"found {len(files)} files to process", fg=typer.colors.GREEN)
    return files


# Originally this whole function was retried, but tmpdir flakiness will throw
# exceptions in backoff's context, which ruins things
def parse_and_aggregate_hour(bucket: str, hour: RTAggregation, pbar=None):
    def log(*args, fg=None, **kwargs):
        # capture fg so we don't pass it to pbar
        if pbar:
            pbar.write(*args, **kwargs)
        else:
            typer.secho(*args, fg=fg, **kwargs)

    fs = get_fs()

    out_path = f"{hour.hive_path}{EXTENSION}"  # probably a better way to do this

    with tempfile.TemporaryDirectory() as tmp_dir:
        fs.get(
            rpath=[file.path for file in hour.source_files],
            lpath=[os.path.join(tmp_dir, file.path) for file in hour.source_files],
        )
        gzip_fname = str(tmp_dir + "/" + "temporary" + EXTENSION)
        written = 0
        with gzip.open(gzip_fname, "w") as gzipfile:
            for rt_file in hour.source_files:
                feed = gtfs_realtime_pb2.FeedMessage()

                try:
                    with open(os.path.join(tmp_dir, rt_file.path), "rb") as f:
                        feed.ParseFromString(f.read())
                    parsed = json_format.MessageToDict(feed)
                except DecodeError:
                    log(
                        f"WARN: got DecodeError for {str(rt_file.path)}",
                        fg=typer.colors.YELLOW,
                    )
                    continue

                if not parsed or "entity" not in parsed:
                    log(
                        f"WARNING: no records found in {str(rt_file.path)}",
                        fg=typer.colors.YELLOW,
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

        if written:
            log(f"writing {written} lines from {str(rt_file.path)} to {out_path}")
            put_with_retry(fs, gzip_fname, out_path)
        else:
            log(
                f"WARNING: no records at all for {hour.hive_path}",
                fg=typer.colors.YELLOW,
            )

    if pbar:
        pbar.update(1)


def try_handle_one_feed(*args, **kwargs) -> Optional[Exception]:
    try:
        parse_and_aggregate_hour(*args, **kwargs)
    except Exception as e:
        typer.echo(
            f"got exception while handling feed: {str(e)} from {str(e.__cause__ or e.__context__)} {traceback.format_exc()}",
            err=True,
        )
        # a lot of these are thrown by tmpdir, and are potentially flakes; but if they were thrown during
        # handling of another exception, we want that exception still
        if isinstance(e, OSError) and e.errno == 39:
            return e.__cause__ or e.__context__
        return e


def main(
    file_type: RTFileType,
    glob: str,
    dst_bucket: str,
    limit: int = 0,
    progress: bool = typer.Option(
        False,
        help="If true, display progress bar; useful for development but not in production.",
    ),
    threads: int = 4,
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
            source_files=files,
        )
        for hive_path, files in feed_hours.items()
    ]

    if limit:
        structlog.get_logger().warn(f"limit of {limit} feeds was set")
        feed_hours = feed_hours[:limit]

    pbar = tqdm(total=len(feed_hours)) if progress else None

    # gcfs does not seem to play nicely with multiprocessing right now, so use threads :(
    # https://github.com/fsspec/gcsfs/issues/379
    with ThreadPoolExecutor(max_workers=threads) as pool:
        args = [
            (
                dst_bucket,
                hour,
                pbar,
            )
            for hour in feed_hours
        ]
        exceptions = [ret for ret in pool.map(try_handle_one_feed, *zip(*args)) if ret]

    if exceptions:
        msg = f"got {len(exceptions)} exceptions from processing {len(feed_hours)} feeds: {exceptions}"
        typer.secho(msg, err=True, fg=typer.colors.RED)
        raise RuntimeError(msg)

    typer.secho("fin.", fg=typer.colors.MAGENTA)


if __name__ == "__main__":
    typer.run(main)
