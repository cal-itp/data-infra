# fmt: off
from gevent import monkey; monkey.patch_all()  # noqa
# fmt: on
"""
This pretty much exists just to start an in-process Prometheus server since
Huey's startup hooks are per _worker_ and not the overall consumer process.
"""
from huey.constants import WORKER_GREENLET

import logging
import sys

from huey.consumer_options import ConsumerConfig
from prometheus_client import start_http_server

from gtfs_rt_archiver_v2.tasks import huey

if __name__ == "__main__":
    # this is straight from huey_consumer.py
    if sys.version_info >= (3, 8) and sys.platform == "darwin":
        import multiprocessing

        try:
            multiprocessing.set_start_method("fork")
        except RuntimeError:
            pass
    start_http_server(8000)
    config = ConsumerConfig(
        workers=64,
        periodic=False,
        worker_type=WORKER_GREENLET,
    )
    logger = logging.getLogger("huey")
    config.setup_logger(logger)
    huey.create_consumer(**config.values).run()
