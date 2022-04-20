"""
Parses binary RT feeds and writes them back to GCS as gzipped newline-delimited JSON
"""
import gzip
import json
import os
import tempfile
import traceback
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
from calitp.config import get_bucket
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


class RTFileTypePrefix(str, Enum):
    al = "al"
    tu = "tu"
    rt = "rt"


class RTFileType(str, Enum):
    service_alerts = "service_alerts"
    trip_updates = "trip_updates"
    vehicle_positions = "vehicle_positions"


class RTFile(BaseModel):
    prefix: RTFileTypePrefix
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
            f"url={self.url}",
            f"hour={self.tick.hour}",
            f"minute={self.tick.minute}",
            f"second={self.tick.second}",
            self.path.name,
        )


# Try twice in the event we get a ClientResponseError; doesn't have much of a delay (like 0.01s)
@backoff.on_exception(backoff.expo, exception=ClientResponseError, max_tries=3)
def get_with_retry(fs, *args, **kwargs):
    return fs.get(*args, **kwargs)


@backoff.on_exception(backoff.expo, exception=ClientResponseError, max_tries=3)
def put_with_retry(fs, *args, **kwargs):
    return fs.put(*args, **kwargs)


def parse_pb(path, open_func=open) -> dict:
    """
    Convert pb file to Python dictionary
    """
    feed = gtfs_realtime_pb2.FeedMessage()
    try:
        with open_func(path, "rb") as f:
            feed.ParseFromString(f.read())
        d = json_format.MessageToDict(feed)
        return d
    except DecodeError:
        typer.secho("WARN: got DecodeError for {}".format(path), fg=typer.colors.YELLOW)
        return {}


def identify_files(
    glob, prefix: RTFileTypePrefix, rt_file_type: RTFileType, progress=False
) -> List[RTFile]:
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
                    prefix=prefix,
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
def parse_file(bucket: str, rt_file: RTFile, pbar=None):
    fs = get_fs()

    with tempfile.TemporaryDirectory() as tmp_dir:
        parsed = parse_pb(rt_file.path, open_func=fs.open)

        if not parsed or "entity" not in parsed:
            msg = f"WARNING: no records found in {str(rt_file.path)}"
            if pbar:
                pbar.write(msg)
                pbar.update(1)
            else:
                typer.secho(msg, fg=typer.colors.YELLOW)
            return

        gzip_fname = str(tmp_dir + "/" + "temporary" + EXTENSION)
        written = 0

        with gzip.open(gzip_fname, "w") as gzipfile:
            for record in parsed["entity"]:
                record.update(
                    {
                        "header": parsed["header"],
                        "metadata": rt_file.json(),
                    }
                )
                gzipfile.write((json.dumps(record) + "\n").encode("utf-8"))
                written += 1

        out_path = f"{rt_file.hive_path(bucket)}{EXTENSION}"  # probably a better way to do this
        msg = f"writing {written} lines from {str(rt_file.path)} to {out_path}"
        if pbar:
            pbar.write(msg)
        else:
            typer.echo(msg)
        put_with_retry(fs, gzip_fname, out_path)
        if pbar:
            pbar.update(1)


def try_handle_one_feed(*args, **kwargs) -> Optional[Exception]:
    try:
        parse_file(*args, **kwargs)
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
    prefix: RTFileTypePrefix,
    file_type: RTFileType,
    glob: str = f"{get_bucket()}/rt/{yesterday}T12:*",
    dst_bucket=get_bucket(),
    limit: int = 0,
    progress: bool = False,
    threads: int = 4,
):
    typer.secho(f"Parsing {prefix}/{file_type} from {glob}", fg=typer.colors.MAGENTA)

    # fetch files ----
    feed_files = identify_files(
        glob=glob, prefix=prefix, rt_file_type=file_type, progress=progress
    )

    if limit:
        structlog.get_logger().warn(f"limit of {limit} feeds was set")
        feed_files = feed_files[:limit]

    if progress:
        pbar = tqdm(total=len(feed_files))
    else:
        pbar = None

    # gcfs does not seem to play nicely with multiprocessing right now, so use threads :(
    # https://github.com/fsspec/gcsfs/issues/379
    with ThreadPoolExecutor(max_workers=threads) as pool:
        args = [
            (
                dst_bucket,
                file,
                pbar,
            )
            for file in feed_files
        ]
        exceptions = [ret for ret in pool.map(try_handle_one_feed, *zip(*args)) if ret]

    if exceptions:
        msg = f"got {len(exceptions)} exceptions from processing {len(feed_files)} feeds: {exceptions}"
        typer.secho(msg, err=True, fg=typer.colors.RED)
        raise RuntimeError(msg)

    typer.secho("fin.", fg=typer.colors.MAGENTA)


if __name__ == "__main__":
    typer.run(main)
