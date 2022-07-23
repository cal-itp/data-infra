import os
from datetime import datetime

import orjson
import pendulum
import structlog
import typer
from calitp.storage import AirtableGTFSDataRecord, download_feed
from google.cloud import storage
from huey import RedisExpireHuey
from huey.registry import Message
from huey.serializer import Serializer
from requests import HTTPError

from .metrics import (
    FETCH_PROCESSING_TIME,
    FEEDS_DOWNLOADED,
    TASK_SIGNALS,
    FETCH_PROCESSING_DELAY,
    FETCH_PROCESSED_BYTES,
    FEED_REQUEST_FAILURES,
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
    name="gtfs-rt-archiver-v3",
    results=False,
    # serializer=PydanticSerializer(),
    url=os.getenv("CALITP_HUEY_REDIS_URL"),
    host=os.getenv("CALITP_HUEY_REDIS_HOST", os.getenv("KUBERNETES_SERVICE_HOST")),
    port=os.getenv("CALITP_HUEY_REDIS_PORT", os.getenv("KUBERNETES_SERVICE_PORT")),
    password=os.getenv("CALITP_HUEY_REDIS_PASSWORD"),
)


client = storage.Client()

base_logger = structlog.get_logger()


@huey.signal()
def instrument_signals(signal, task, exc=None):
    TASK_SIGNALS.labels(signal=signal, exc_type=str(exc)).inc()


auth_dict = None


@huey.on_startup()
def load_auth_dict():
    global auth_dict
    auth_dict = {
        key: os.environ[key]
        for key in [
            "AC_TRANSIT_API_KEY",
            "AMTRAK_GTFS_URL",
            "CULVER_CITY_API_KEY",
            "MTC_511_API_KEY",
            "SD_MTS_SA_API_KEY",
            "SD_MTS_VP_TU_API_KEY",
            "SWIFTLY_AUTHORIZATION_KEY_CALITP",
        ]
    }


@huey.task(expires=5)
def fetch(tick: datetime, record: AirtableGTFSDataRecord):
    logger = base_logger.bind(
        tick=tick,
        record_name=record.name,
        record_uri=record.uri,
    )
    slippage = (pendulum.now() - tick).total_seconds()
    FETCH_PROCESSING_DELAY.labels(url=record.uri).observe(slippage)

    with FETCH_PROCESSING_TIME.labels(url=record.uri).time():
        with FEED_REQUEST_FAILURES.labels(url=record.uri).count_exceptions():
            # TODO: can we either get the content bytes without using memory
            #   or persist on disk in between?
            try:
                extract, content = download_feed(record, auth_dict)
            except HTTPError as e:
                logger.exception(
                    "http error occurred while downloading feed",
                    code=e.response.status_code,
                )
                raise
            except Exception as e:
                logger.exception(
                    "other exception occurred while downloading feed", exc_type=type(e)
                )
                raise

        typer.secho(f"saving {len(content)} bytes from {record.uri} to {extract.path}")
        extract.save_content(content=content, client=client)
        FETCH_PROCESSED_BYTES.labels(record.uri).inc(len(content))
        FEEDS_DOWNLOADED.labels(url=record.uri).inc()
