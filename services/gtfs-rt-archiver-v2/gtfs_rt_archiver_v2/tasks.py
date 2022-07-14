import base64
import os
import random
from datetime import datetime

import orjson
import pendulum
import requests
import yaml
from calitp.storage import AirtableGTFSDataRecord, download_feed
from google.cloud import storage
from huey import RedisHuey
from huey.registry import Message
from huey.serializer import Serializer

from .metrics import (
    HANDLE_TICK_PROCESSING_TIME,
    FEEDS_DOWNLOADED,
    TASK_SIGNALS,
    HANDLE_TICK_PROCESSING_DELAY,
    HANDLE_TICK_PROCESSED_BYTES, FEED_REQUEST_FAILURES,
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


huey = RedisHuey(
    name="gtfs-rt-archiver-2",
    results=False,
    # serializer=PydanticSerializer(),
    host="localhost",
)

client = storage.Client()


@huey.signal()
def instrument_signals(signal, task, exc=None):
    TASK_SIGNALS.labels(signal=signal, exc_type=str(exc)).inc()


auth_dict = {}


@huey.on_startup()
def read_auth_dict():
    with open(os.environ["CALITP_API_KEYS_YML"]) as f:
        auth_dict = yaml.load(f, Loader=yaml.SafeLoader)


@huey.task(expires=5)
def fetch(tick: datetime, record: AirtableGTFSDataRecord):
    with HANDLE_TICK_PROCESSING_TIME.labels(url=record.uri).time():
        r = random.random()
        if r > 0.99:
            raise RuntimeError

        with FEED_REQUEST_FAILURES.labels(url=record.uri).count_exceptions():
            extract, content = download_feed(record, auth_dict)
        slippage = (pendulum.now() - tick).total_seconds()
        HANDLE_TICK_PROCESSING_DELAY.labels(url=record.uri).observe(slippage)

        storage.Blob(
            name=name,
            bucket=client.bucket("gtfs-data-rt-sandbox"),
        ).upload_from_string(
            data=content,
            content_type="application/octet-stream",
            client=client,
        )
        HANDLE_TICK_PROCESSED_BYTES.labels(url).inc(len(content))
        FEEDS_DOWNLOADED.labels(url=url).inc()
