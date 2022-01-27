import os
import sys
import logging
import pathlib
import queue
import time
import yaml
from .threads.ticker import Ticker
from .threads.fetcher import PoolFetcher
from .threads.writer import FSWriter, GCPBucketWriter
from .threads.mappers import YamlMapper
from .eventbus import EventBus
from .threadpool import ThreadPool
from .parsers import parse_agencies_urls, parse_headers

def main():

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

    logger = logging.getLogger('gtfs-rt-archive')

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

    # Instantiate threads

    qmap = { 'write': queue.Queue() }
    evtbus = EventBus(logger)
    threadcfg_map = {
      'agencies': YamlMapper(logger, evtbus, agencies_path, parse_agencies_urls),
      'headers': YamlMapper(logger, evtbus, headers_path, parse_headers)
    }
    pool = ThreadPool(logger, evtbus, qmap, PoolFetcher, threadcfg_map)
    ticker = Ticker(logger, evtbus, tickint)
    writer = None

    for scheme in backends_table:
        if data_dest.startswith(scheme):
            writercls = backends_table[scheme]
            writer = writercls(logger, qmap['write'], data_dest, secret)
            break

    if writer is None:
        logger.error(
            "unsupported CALITP_DATA_DEST: "
            "{}: using default value file:///dev/null".format(data_dest)
        )
        writer = FSWriter(logger, qmap['write'], "file:///dev/null")

    # Load data
    for cfg_container in threadcfg_map.values():
      cfg_container.load_datasrc()

    # Run

    writer.start()
    pool.start()
    for cfg_container in threadcfg_map.values():
      cfg_container.start()
    # wait on thread startup
    time.sleep(0.5)
    ticker.start()
    ticker.join()
