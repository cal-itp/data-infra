import base64
import random

import requests
from google.cloud import storage
from huey import RedisHuey

from .metrics import (
    HANDLE_TICK_PROCESSING_TIME,
    FEEDS_IN_PROGRESS,
    FEEDS_DOWNLOADED,
    TASK_SIGNALS,
)
from .models import FetchTask

huey = RedisHuey("gtfs-rt-archiver-2", host="localhost")

client = storage.Client()


@huey.signal()
def instrument_signals(signal, task, exc=None):
    TASK_SIGNALS.labels(signal=signal, exc_type=str(exc)).inc()


@huey.task(expires=5)
def fetch(task: FetchTask):
    with HANDLE_TICK_PROCESSING_TIME.labels(
        url=task.url
    ).time(), FEEDS_IN_PROGRESS.labels(url=task.url).track_inprogress():
        r = random.random()
        if r > 0.99:
            raise RuntimeError
        resp = requests.get(task.url)
        name = "/".join(
            [
                "rt_protos",
                f"dt={task.tick.dt.to_date_string()}",
                f"hour={task.tick.dt.hour}",
                f"time={task.tick.dt.to_time_string()}",
                f"{task.n}__{base64.urlsafe_b64encode(task.url.encode()).decode()}",
            ]
        )
        storage.Blob(
            name=name,
            bucket=client.bucket("gtfs-data-rt-sandbox"),
        ).upload_from_string(
            data=resp.content,
            content_type="application/octet-stream",
            client=client,
        )

        FEEDS_DOWNLOADED.labels(url=task.url).inc()
