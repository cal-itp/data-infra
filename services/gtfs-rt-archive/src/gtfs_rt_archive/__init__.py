import os
import sys
import logging
import pathlib
import queue
import time
import structlog
from .threads.ticker import Ticker
from .threads.fetcher import PoolFetcher
from .threads.writer import FSWriter, GCPBucketWriter
from .threads.mappers import YamlMapper
from .eventbus import EventBus
from .threadpool import ThreadPool
from .mapperfns import map_agencies_urls, map_headers


def main():

    logging.basicConfig(format="%(messages)s", stream=sys.stdout, level=logging.warning)

    structlog.configure(
        processors=[
            structlog.stdlib.filter_by_level,
            # Adds logger=module_name (e.g __main__)
            structlog.stdlib.add_logger_name,
            # Adds level=info, debug, etc.
            structlog.stdlib.add_log_level,
            # Performs the % string interpolation as expected
            structlog.stdlib.PositionalArgumentsFormatter(),
            # Include the stack when stack_info=True
            structlog.processors.StackInfoRenderer(),
            # Include the exception when exc_info=True
            # e.g log.exception() or log.warning(exc_info=True)'s behavior
            structlog.processors.format_exc_info,
            # timestamp is UTC
            structlog.processors.TimeStamper(),
            # render final event dict as json
            structlog.processors.JSONRenderer(),
        ],
        # maybe below is not needed?
        context_class=dict,
        # Provides the logging.Logger for the underlaying log call
        logger_factory=structlog.stdlib.LoggerFactory(),
        # Provides predefined methods - log.debug(), log.info(), etc.
        wrapper_class=structlog.stdlib.BoundLogger,
        # Caching of our logger
        cache_logger_on_first_use=True,
    )

    backends_table = {"file://": FSWriter, "gs://": GCPBucketWriter}

    # Setup logging channel

    # logger = logging.getLogger("gtfs-rt-archive")
    logger = structlog.getLogger("gtfs-rt-archive")

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

    qmap = {"write": queue.Queue()}
    evtbus = EventBus(logger)
    mappers = {
        "urls": YamlMapper(logger, evtbus, agencies_path, map_agencies_urls),
        "headers": YamlMapper(logger, evtbus, headers_path, map_headers),
    }
    pool = ThreadPool(logger, evtbus, qmap, PoolFetcher, mappers)
    ticker = Ticker(logger, evtbus, tickint)
    writer = None

    for scheme in backends_table:
        if data_dest.startswith(scheme):
            writercls = backends_table[scheme]
            writer = writercls(logger, qmap["write"], data_dest, secret)
            break

    if writer is None:
        logger.error(
            "unsupported CALITP_DATA_DEST: "
            "{}: using default value file:///dev/null".format(data_dest)
        )
        writer = FSWriter(logger, qmap["write"], "file:///dev/null")

    # Load data
    for mapper in mappers.values():
        mapper.load_map()

    # Run

    writer.start()
    pool.start()
    for mapper in mappers.values():
        mapper.start()
    # wait on thread startup
    time.sleep(0.5)
    ticker.start()
    ticker.join()
