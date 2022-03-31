"""
Parses binary RT feeds and writes them back to GCS as gzipped newline-delimited JSON
"""
import gzip
import itertools
import json
import os
import tempfile
from collections import defaultdict
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timedelta, date
from enum import Enum
from pathlib import Path
from typing import Optional

import aiohttp
import backoff
import humanize
import structlog
import typer
from calitp.config import get_bucket
from calitp.storage import get_fs
from google.protobuf import json_format
from google.protobuf.message import DecodeError
from google.transit import gtfs_realtime_pb2
from tqdm import tqdm


# Note that all RT extraction is stored in the prod bucket, since it is very large,
# but we can still output processed results to the staging bucket

EXTENSION = ".jsonl.gz"


def parse_pb(path, logger, open_func=open) -> dict:
    """
    Convert pb file to Python dictionary
    """
    feed = gtfs_realtime_pb2.FeedMessage()
    try:
        with open_func(path, "rb") as f:
            feed.ParseFromString(f.read())
        d = json_format.MessageToDict(feed)
        d.update({"calitp_filepath": path})
        return d
    except DecodeError:
        logger.warn("WARN: got DecodeError for {}".format(path))
        return {}


def fetch_bucket_file_names(src_path, rt_file_substring, iso_date, progress=False):
    # posix_date = str(time.mktime(execution_date.timetuple()))[:6]
    fs = get_fs()
    # get rt files
    glob = src_path + iso_date + "*"
    print("Globbing rt bucket {}".format(glob))
    before = datetime.now()
    rt = fs.glob(glob)
    print(f"globbing took {(datetime.now() - before).total_seconds()} seconds")

    buckets_to_parse = len(rt)
    print("Realtime buckets to parse: {i}".format(i=buckets_to_parse))

    # organize rt files by itpId_urlNumber
    if progress:
        rt = tqdm(rt)
    rt_files = [fs.ls(r) for r in rt]

    entity_files = [
        item
        for sublist in rt_files
        for item in sublist
        if rt_file_substring.name in item
    ]

    print(f"entity files len {len(entity_files)}")

    feed_files = defaultdict(lambda: [])

    for fname in entity_files:
        itpId, urlNumber = fname.split("/")[-3:-1]
        feed_files[(itpId, urlNumber)].append(fname)

    # for some reason the fs.glob command takes up a fair amount of memory here,
    # and does not seem to free it after the function returns, so we manually clear
    # its caches (at least the ones I could find)
    fs.dircache.clear()

    # Now our feed files dict has a key of itpId_urlNumber and a list of files to
    # parse
    print("found {} feeds to process".format(len(feed_files.keys())))
    return feed_files


def get_google_cloud_filename(filename_prefix, feed, iso_date):
    itp_id_url_num = "_".join(map(str, feed))
    prefix = filename_prefix
    return f"{prefix}_{iso_date}_{itp_id_url_num}{EXTENSION}"


# Try twice in the event we get a ClientResponseError; doesn't have much of a delay (like 0.01s)
@backoff.on_exception(
    backoff.expo, aiohttp.client_exceptions.ClientResponseError, max_tries=2
)
def handle_one_feed(feed, files, filename_prefix, iso_date, dst_path, logger):
    start = datetime.now()

    logger.info("entering handle_one_feed")

    fs = get_fs()

    if not files:
        logger.warn("got no files, returning early")
        return

    google_cloud_file_name = get_google_cloud_filename(filename_prefix, feed, iso_date)
    logger.info("Creating {} from {} files".format(google_cloud_file_name, len(files)))
    # fetch and parse RT files from bucket
    with tempfile.TemporaryDirectory() as tmp_dir:
        logger.info(f"downloading {len(files)} files to {tmp_dir}")
        fs.get(files, tmp_dir)
        all_files = [x for x in Path(tmp_dir).rglob("*") if not x.is_dir()]

        gzip_fname = str(tmp_dir + "/" + "temporary" + EXTENSION)
        written = 0

        with gzip.open(gzip_fname, "w") as gzipfile:
            for feed_fname in all_files:
                # convert protobuff objects to DataFrames
                parsed = parse_pb(feed_fname, logger=logger)

                if parsed and "entity" in parsed:
                    for record in parsed["entity"]:
                        record["header"] = parsed["header"]
                        record["calitp_filepath"] = str(parsed["calitp_filepath"])
                        record["calitp_itp_id"] = int(feed[0])
                        record["calitp_url_number"] = int(feed[1])
                        gzipfile.write((json.dumps(record) + "\n").encode("utf-8"))
                        written += 1

        if not written:
            logger.warning("did not parse any entities, skipping upload")
            return

        filesize = humanize.naturalsize(os.stat(gzip_fname).st_size)
        logger.info(
            f"writing {written} lines ({filesize}) from {gzip_fname} to {dst_path + google_cloud_file_name}"
        )
        fs.put(
            gzip_fname,
            dst_path + google_cloud_file_name,
        )
        logger.info(
            "took {} seconds to process {} files".format(
                (datetime.now() - start).total_seconds(), len(all_files)
            )
        )


def try_handle_one_feed(
    i, feed, files, filename_prefix, iso_date, dst_path, total_feeds
) -> Optional[Exception]:
    logger = structlog.get_logger().bind(
        i=i,
        feed=feed,
        len_files=len(files),
        filename_prefix=filename_prefix,
        iso_date=iso_date,
        dst_path=dst_path,
        total_feeds=total_feeds,
    )
    try:
        handle_one_feed(feed, files, filename_prefix, iso_date, dst_path, logger)
    except Exception as e:
        logger.error(f"got exception while handling feed: {str(e)}")
        return e


class Prefix(str, Enum):
    al = "al"
    tu = "tu"
    rt = "rt"


class RTFileType(str, Enum):
    service_alerts = "service_alerts"
    trip_updates = "trip_updates"
    vehicle_positions = "vehicle_positions"


yesterday = (date.today() - timedelta(days=1)).isoformat()


def main(
    filename_prefix: Prefix,
    rt_file_substring: RTFileType,
    iso_date: str = yesterday,
    src_path=f"{get_bucket()}/rt/",
    dst_path=f"{get_bucket()}/rt-processed/",
    limit: int = 0,
    progress: bool = False,
    threads: int = 4,
):
    # get execution_date from context:
    # https://stackoverflow.com/questions/59982700/airflow-how-can-i-access-execution-date-on-my-custom-operator

    actual_dst_path = os.path.join(dst_path, rt_file_substring.name, "")

    typer.echo(
        f"Parsing {filename_prefix}/{rt_file_substring} from {os.path.join(src_path, iso_date)} to {actual_dst_path}"
    )

    # fetch files ----
    feed_files = fetch_bucket_file_names(
        src_path, rt_file_substring, iso_date, progress=progress
    )

    enumerated = enumerate(feed_files.items())
    if limit:
        structlog.get_logger().warn(f"limit of {limit} feeds was set")
        enumerated = itertools.islice(enumerated, limit)
    enumerated = list(enumerated)

    # gcfs does not seem to play nicely with multiprocessing right now
    # https://github.com/fsspec/gcsfs/issues/379
    with ThreadPoolExecutor(max_workers=threads) as pool:
        args = [
            (
                i,
                feed,
                files,
                filename_prefix,
                iso_date,
                actual_dst_path,
                len(feed_files),
            )
            for i, (feed, files) in enumerated
        ]
        exceptions = [ret for ret in pool.map(try_handle_one_feed, *zip(*args)) if ret]

    if exceptions:
        raise RuntimeError(
            f"got {len(exceptions)} exceptions from processing {len(enumerated)} feeds: {exceptions}"
        )


if __name__ == "__main__":
    typer.run(main)
