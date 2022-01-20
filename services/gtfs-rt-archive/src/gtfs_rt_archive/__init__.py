import os
import sys
import logging
import pathlib
import queue
import yaml
from .threads.ticker import Ticker
from .threads.fetcher import Fetcher
from .threads.writer import FSWriter, GCPBucketWriter
from .eventbus import EventBus


def main(argv):

    # Config tables

    level_table = {
        "debug": logging.DEBUG,
        "info": logging.INFO,
        "warning": logging.WARNING,
        "error": logging.ERROR,
        "critical": logging.CRITICAL,
    }

    backends_table = {"file://": FSWriter, "gs://": GCPBucketWriter}

    # Setup logging channel

    logger = logging.getLogger(argv[0])

    level_name = os.getenv("CALITP_LOG_LEVEL")
    if hasattr(level_name, "lower"):
        level_name = level_name.lower()
    level = level_table.get(level_name, logging.WARNING)

    logging.basicConfig(stream=sys.stdout, level=level)

    # Parse environment

    agencies_path = os.getenv("CALITP_AGENCIES_YML")
    headers_path = os.getenv("CALITP_HEADERS_YML")
    tickint = os.getenv("CALITP_TICK_INT")
    data_dest = os.getenv("CALITP_DATA_DEST")
    secret = os.getenv("CALITP_DATA_DEST_SECRET")

    if agencies_path:
        agencies_path = pathlib.Path(agencies_path)
    else:
        agencies_path = pathlib.Path(os.getcwd(), "agencies.yml")

    if headers_path:
        headers_path = pathlib.Path(headers_path)
    else:
        headers_path = pathlib.Path(os.getcwd(), "headers.yml")

    if tickint:
        tickint = int(tickint)
    else:
        tickint = 20

    if not data_dest:
        data_dest = "file:///dev/null"

    # Load data

    headers = parse_headers(logger, headers_path)
    feeds = parse_feeds(logger, agencies_path, headers)

    # Instantiate threads

    wq = queue.Queue()
    evtbus = EventBus(logger)
    ticker = Ticker(logger, evtbus, tickint)
    writer = None

    for scheme in backends_table:
        if data_dest.startswith(scheme):
            writercls = backends_table[scheme]
            writer = writercls(logger, wq, data_dest, secret)
            break

    if writer is None:
        logger.warning(
            "unsupported CALITP_DATA_DEST: "
            "{}: using default value file:///dev/null".format(data_dest)
        )
        writer = FSWriter(logger, wq, "file:///dev/null")

    fetchers = []
    for feed in feeds:
        fetchers.append(Fetcher(logger, evtbus, wq, feed))

    # Run

    writer.start()
    for fetcher in fetchers:
        fetcher.start()
    ticker.start()
    ticker.join()


def parse_headers(logger, headers_src):

    headers = {}

    with headers_src.open() as f:
        headers_src_data = yaml.load(f, Loader=yaml.SafeLoader)
        for item in headers_src_data:
            for url_set in item["URLs"]:
                itp_id = url_set["itp_id"]
                url_number = url_set["url_number"]
                for rt_url in url_set["rt_urls"]:
                    key = f"{itp_id}/{url_number}/{rt_url}"
                    if key in headers:
                        raise ValueError(
                            f"Duplicate header data for url with key: {key}"
                        )
                    headers[key] = item["header-data"]

    logger.info(f"Header file successfully parsed with {len(headers)} entries")
    return headers


def parse_feeds(logger, feeds_src, headers):

    feeds = []

    with feeds_src.open() as f:

        feeds_src_data = yaml.load(f, Loader=yaml.SafeLoader)
        for agency_name, agency_def in feeds_src_data.items():

            if "feeds" not in agency_def:
                logger.warning(
                    "agency {}: skipped loading "
                    "invalid definition (missing feeds)".format(agency_name)
                )
                continue

            if "itp_id" not in agency_def:
                logger.warning(
                    "agency {}: skipped loading "
                    "invalid definition (missing itp_id)".format(agency_name)
                )
                continue

            for i, feed_set in enumerate(agency_def["feeds"]):
                for feed_name, feed_url in feed_set.items():
                    if feed_name.startswith("gtfs_rt") and feed_url:

                        agency_itp_id = agency_def["itp_id"]
                        key = "{}/{}/{}".format(agency_itp_id, i, feed_name)
                        feeds.append((key, feed_url, headers.get(key, {}),))

    return feeds
