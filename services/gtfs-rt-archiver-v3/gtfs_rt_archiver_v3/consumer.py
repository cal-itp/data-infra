"""
This pretty much exists just to start an in-process Prometheus server since
Huey's startup hooks are per _worker_ and not the overall consumer process.
"""
import typer
import os

from calitp.auth import load_secrets
from huey.constants import WORKER_THREAD

import logging
import sys

from huey.consumer_options import ConsumerConfig
from prometheus_client import start_http_server

from .tasks import huey


def main(
    port: int = os.getenv("CONSUMER_PROMETHEUS_PORT", 9102),
    load_env_secrets: bool = False,
):
    start_http_server(port)

    if load_env_secrets:
        load_secrets()

    config = ConsumerConfig(
        workers=int(os.getenv("HUEY_CONSUMER_WORKERS", 32)),
        periodic=False,
        worker_type=WORKER_THREAD,
    )
    logger = logging.getLogger("huey")
    config.setup_logger(logger)
    huey.create_consumer(**config.values).run()


if __name__ == "__main__":
    # this is straight from huey_consumer.py
    if sys.version_info >= (3, 8) and sys.platform == "darwin":
        import multiprocessing

        try:
            multiprocessing.set_start_method("fork")
        except RuntimeError:
            pass
    typer.run(main)
