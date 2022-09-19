import os
import traceback
from datetime import datetime

import backoff
import humanize
import orjson
import pendulum
import structlog
import typer
from calitp.storage import download_feed, GTFSDownloadConfig, GTFSFeedExtract
from google.cloud import storage, secretmanager
import google_crc32c
from huey import RedisExpireHuey
from huey.registry import Message
from huey.serializer import Serializer
from requests import HTTPError, RequestException

from .metrics import (
    FETCH_PROCESSING_TIME,
    TASK_SIGNALS,
    FETCH_PROCESSING_DELAY,
    FETCH_PROCESSED_BYTES,
)


class PydanticSerializer(Serializer):
    def _serialize(self, data: Message) -> bytes:
        return orjson.dumps(data._asdict())

    def _deserialize(self, data: bytes) -> Message:
        # deal with datetimes manually
        d = orjson.loads(data)
        d["expires_resolved"] = datetime.fromisoformat(d["expires_resolved"])
        d["kwargs"]["tick"] = datetime.fromisoformat(d["kwargs"]["tick"])
        return Message(*d.values())


huey = RedisExpireHuey(
    name=f"gtfs-rt-archiver-v3-{os.environ['AIRFLOW_ENV']}",
    expire_time=5,
    results=False,
    # serializer=PydanticSerializer(),
    url=os.getenv("CALITP_HUEY_REDIS_URL"),
    host=os.getenv("CALITP_HUEY_REDIS_HOST"),
    port=os.getenv("CALITP_HUEY_REDIS_PORT"),
    password=os.getenv("CALITP_HUEY_REDIS_PASSWORD"),
)


client = storage.Client()

structlog.configure(processors=[structlog.processors.JSONRenderer()])
base_logger = structlog.get_logger()


@huey.signal()
def instrument_signals(signal, task, exc=None):
    config: GTFSDownloadConfig = task.kwargs["config"]
    TASK_SIGNALS.labels(
        record_name=config.name,
        record_uri=config.url,
        record_feed_type=config.feed_type,
        signal=signal,
        exc_type=type(exc).__name__ if exc else "",
    ).inc()


AUTH_KEYS = [
    "AC_TRANSIT_API_KEY",
    "AMTRAK_GTFS_URL",
    "CULVER_CITY_API_KEY",
    # TODO: this can be removed once we've confirmed it's no longer in Airtable
    "GRAAS_SERVER_URL",
    "MTC_511_API_KEY",
    "SD_MTS_SA_API_KEY",
    "SD_MTS_VP_TU_API_KEY",
    "SWIFTLY_AUTHORIZATION_KEY_CALITP",
    "WEHO_RT_KEY",
]
auth_dict = None


def load_secrets():
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


@huey.on_startup()
def load_auth_dict():
    global auth_dict
    auth_dict = {key: os.environ[key] for key in AUTH_KEYS}


@backoff.on_exception(
    backoff.expo,
    exception=(Exception,),
    max_tries=2,
)
def save_content_with_retry(extract: GTFSFeedExtract, content: bytes) -> None:
    extract.save_content(content=content, client=client)


@huey.task(expires=5)
def fetch(tick: datetime, config: GTFSDownloadConfig):
    labels = dict(
        record_name=config.name,
        record_uri=config.url,
        record_feed_type=config.feed_type,
    )
    logger = base_logger.bind(
        tick=tick.isoformat(),
        **labels,
    )
    slippage = (pendulum.now() - tick).total_seconds()
    FETCH_PROCESSING_DELAY.labels(**labels).observe(slippage)

    with FETCH_PROCESSING_TIME.labels(**labels).time():
        try:
            extract, content = download_feed(
                config=config,
                auth_dict=auth_dict,
                ts=tick,
            )
        except HTTPError as e:
            logger.error(
                "unexpected HTTP response code from feed request",
                code=e.response.status_code,
                content=e.response.text,
                exc_type=type(e).__name__,
                exc_str=str(e),
                traceback=traceback.format_exc(),
            )
            raise
        except RequestException as e:
            logger.error(
                "request exception occurred from feed request",
                exc_type=type(e).__name__,
                exc_str=str(e),
                traceback=traceback.format_exc(),
            )
            raise
        except Exception as e:
            logger.error(
                "other non-request exception occurred during download_feed",
                exc_type=type(e).__name__,
                exc_str=str(e),
                traceback=traceback.format_exc(),
            )
            raise

        typer.secho(
            f"saving {humanize.naturalsize(len(content))} from {config.url} to {extract.path}"
        )
        try:
            save_content_with_retry(extract=extract, content=content)
        except Exception as e:
            logger.error(
                "failure occurred when saving extract or metadata",
                exc_type=type(e).__name__,
                exc_str=str(e),
                traceback=traceback.format_exc(),
            )
            raise
        FETCH_PROCESSED_BYTES.labels(
            **labels,
            content_type=extract.response_headers.get("Content-Type", "").strip(),
        ).inc(len(content))
