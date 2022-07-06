import base64
import random
from datetime import datetime

import orjson
import pendulum
import requests
from google.cloud import storage
from huey import RedisHuey
from huey.registry import Message
from huey.serializer import Serializer

from .metrics import (
    HANDLE_TICK_PROCESSING_TIME,
    FEEDS_DOWNLOADED,
    TASK_SIGNALS,
    HANDLE_TICK_PROCESSING_DELAY,
    HANDLE_TICK_PROCESSED_BYTES,
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
    serializer=PydanticSerializer(),
    host="localhost",
)

client = storage.Client()


@huey.signal()
def instrument_signals(signal, task, exc=None):
    TASK_SIGNALS.labels(signal=signal, exc_type=str(exc)).inc()


@huey.task(expires=5)
def fetch(tick: datetime, url: str, n: int):
    with HANDLE_TICK_PROCESSING_TIME.labels(url=url).time():
        r = random.random()
        if r > 0.99:
            raise RuntimeError
        resp = requests.get(url)
        content = resp.content
        slippage = (pendulum.now() - tick).total_seconds()
        HANDLE_TICK_PROCESSING_DELAY.labels(url=url).observe(slippage)
        # print(f"{slippage} seconds slippage for url {url}: {} {}")
        name = "/".join(
            [
                "rt_protos",
                f"dt={tick.strftime('%Y-%m-%d')}",
                f"hour={tick.hour}",
                f"time={tick.strftime('%H:%M:%S')}",
                f"{n}__{base64.urlsafe_b64encode(url.encode()).decode()}",
            ]
        )
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
