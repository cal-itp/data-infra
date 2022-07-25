"""
This pretty much exists just to start an in-process Prometheus server since
Huey's startup hooks are per _worker_ and not the overall consumer process.
"""
import typer
import os

from google.cloud import secretmanager
import google_crc32c

from huey.constants import WORKER_THREAD

import logging
import sys

from huey.consumer_options import ConsumerConfig
from prometheus_client import start_http_server

from .tasks import huey, AUTH_KEYS


def main(
    port: int = os.getenv("CONSUMER_PROMETHEUS_PORT", 9102),
    load_auth_keys: bool = False,
):
    start_http_server(port)

    # we have to pull these from secrets manager and write to env since
    # the SDK hangs in a multiprocessing environment aka a huey startup hook
    if load_auth_keys:
        secret_client = secretmanager.SecretManagerServiceClient()
        for key in AUTH_KEYS:
            if key not in os.environ:
                typer.secho(f"fetching secret {key}")
                name = f"projects/cal-itp-data-infra/secrets/{key}/versions/latest"
                response = secret_client.access_secret_version(request={"name": name})

                crc32c = google_crc32c.Checksum()
                crc32c.update(response.payload.data)
                if response.payload.data_crc32c != int(crc32c.hexdigest(), 16):
                    raise ValueError(f"Data corruption detected for secret {name}.")

                os.environ[key] = response.payload.data.decode("UTF-8").strip()

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
