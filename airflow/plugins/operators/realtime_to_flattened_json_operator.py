"""
Parses binary RT feeds and writes them back to GCS as gzipped newline-delimited JSON
"""
import gzip
import json
import os
import tempfile
from collections import defaultdict
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime
from pathlib import Path

import structlog
import typer
from airflow.models import BaseOperator
from airflow.utils.decorators import apply_defaults
from calitp.config import get_bucket
from calitp.storage import get_fs
from google.protobuf import json_format
from google.protobuf.message import DecodeError
from google.transit import gtfs_realtime_pb2


# Note that all RT extraction is stored in the prod bucket, since it is very large,
# but we can still output processed results to the staging bucket


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


def fetch_bucket_file_names(src_path, rt_file_substring, iso_date):
    # posix_date = str(time.mktime(execution_date.timetuple()))[:6]
    fs = get_fs()
    # get rt files
    glob = src_path + iso_date + "*"
    print("Globbing rt bucket {}".format(glob))
    rt = fs.glob(glob)

    buckets_to_parse = len(rt)
    print("Realtime buckets to parse: {i}".format(i=buckets_to_parse))

    # organize rt files by itpId_urlNumber
    rt_files = []
    for r in rt:
        rt_files.append(fs.ls(r))

    entity_files = [
        item for sublist in rt_files for item in sublist if rt_file_substring in item
    ]

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
    return f"{prefix}_{iso_date}_{itp_id_url_num}.gz"


def handle_one_feed(i, feed, files, filename_prefix, iso_date, dst_path):
    start = datetime.now()
    logger = structlog.get_logger().bind(
        i=i,
        feed=feed,
        len_files=len(files),
        filename_prefix=filename_prefix,
        iso_date=iso_date,
        dst_path=dst_path,
    )
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

        gzip_fname = str(tmp_dir + "/" + "temporary" + ".gz")
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

        num_bytes = os.stat(gzip_fname).st_size
        logger.info(
            f"writing {written} lines ({num_bytes} bytes) from {gzip_fname} to {dst_path + google_cloud_file_name}"
        )
        fs.put(
            gzip_fname, dst_path + google_cloud_file_name,
        )
        logger.info(
            "took {} seconds to process {} files".format(
                (datetime.now() - start).total_seconds(), len(all_files)
            )
        )


def execute(context, filename_prefix, rt_file_substring, src_path, dst_path):
    # get execution_date from context:
    # https://stackoverflow.com/questions/59982700/airflow-how-can-i-access-execution-date-on-my-custom-operator
    iso_date = str(context["execution_date"]).split("T")[0]

    # fetch files ----
    feed_files = fetch_bucket_file_names(src_path, rt_file_substring, iso_date)

    # gcfs does not seem to play nicely with multiprocessing right now
    # https://github.com/fsspec/gcsfs/issues/379
    with ThreadPoolExecutor(max_workers=4) as pool:
        args = [
            (i, feed, files, filename_prefix, iso_date, dst_path)
            for i, (feed, files) in enumerate(feed_files.items())
        ]
        list(pool.map(handle_one_feed, *zip(*args)))


class RealtimeToFlattenedJSONOperator(BaseOperator):
    @apply_defaults
    def __init__(
        self, filename_prefix, rt_file_substring, **kwargs,
    ):
        super().__init__(**kwargs)

        # could not just set self.fs here - ran into this issue:
        # https://stackoverflow.com/questions/69532715/google-cloud-functions-using-gcsfs-runtimeerror-this-class-is-not-fork-safe
        # self.fs = get_fs()
        self.filename_prefix = filename_prefix
        self.rt_file_substring = rt_file_substring
        self.src_path = f"{get_bucket()}/rt/"
        self.dst_path = "".join(
            [f"{get_bucket()}/rt-processed/", self.rt_file_substring, "/"]
        )

    def execute(self, context):
        """Process a RT feed of the given type

        Args:
            rt_type (string): One of "alerts", "trip_updates", "vehicle_positions"
            execution_date (date): The execution date being processed
        """
        execute(
            context=context,
            filename_prefix=self.filename_prefix,
            rt_file_substring=self.rt_file_substring,
            src_path=self.src_path,
            dst_path=self.dst_path,
        )


def main(
    execution_date=datetime.combine(datetime.today(), datetime.min.time()).isoformat(),
    filename_prefix="tu",
    rt_file_substring="trip_updates",
    src_path=f"{get_bucket()}/rt/",
    dst_path=f"{get_bucket()}/rt-processed_test_2022-01-27/trip_updates/",
):
    execute(
        {"execution_date": execution_date},
        filename_prefix,
        rt_file_substring,
        src_path,
        dst_path,
    )


if __name__ == "__main__":
    typer.run(main)
