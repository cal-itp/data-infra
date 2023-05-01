"""
This pretty much exists just to start an in-process Prometheus server since
Huey's startup hooks are per _worker_ and not the overall consumer process.
"""
import logging
import os
import re
import sys

import sentry_sdk
import typer
from calitp_data_infra.auth import get_secrets_by_label  # type: ignore
from huey.constants import WORKER_THREAD  # type: ignore
from huey.consumer_options import ConsumerConfig  # type: ignore
from prometheus_client import start_http_server

from .tasks import RTFetchException, huey

compiled_regex = re.compile("0x[0-9a-fA-F]+")


def set_exception_fingerprint(event, hint):
    if "exc_info" not in hint:
        return event

    exception = hint["exc_info"][1]
    if isinstance(exception, RTFetchException):
        # strip out 511 agency ids, since the same outage often affects all of them
        cleaned_url = re.sub(
            pattern=r"agency=\w+$",
            repl="agency=<hidden from fingerprint>",
            string=str(exception.url),
        )
        # use just the type to avoid differentiating based on underlying exceptions as well as object hashes in exception strings
        event["fingerprint"] = [
            type(exception.cause).__name__,
            cleaned_url,
        ]
        if exception.status_code:
            event["fingerprint"].append(str(exception.status_code))

    return event


def main(
    port: int = int(os.getenv("CONSUMER_PROMETHEUS_PORT", 9102)),
    load_env_secrets: bool = False,
):
    sentry_sdk.init(before_send=set_exception_fingerprint)
    start_http_server(port)

    if load_env_secrets:
        for key, value in get_secrets_by_label("gtfs_rt").items():
            os.environ[key] = value

    config = ConsumerConfig(
        workers=int(
            os.getenv("CALITP_HUEY_CONSUMER_WORKERS", 16)
        ),  # seems like a sane default?
        worker_type=WORKER_THREAD,
        backoff=float(os.getenv("CALITP_HUEY_BACKOFF", 1.15)),  # default from huey
        max_delay=float(os.getenv("CALITP_HUEY_MAX_DELAY", 10.0)),  # default from huey
        periodic=False,
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
