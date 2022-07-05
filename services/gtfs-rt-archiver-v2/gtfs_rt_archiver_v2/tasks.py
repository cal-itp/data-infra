import random
import time

import pendulum
from huey import RedisHuey
from prometheus_client import start_http_server

from .metrics import HANDLE_TICK_PROCESSING_TIME, FEEDS_IN_PROGRESS, FEEDS_DOWNLOADED
from .models import Tick

huey = RedisHuey("gtfs-rt-archiver-2", host="localhost")


@huey.on_startup()
def start_prometheus_http_server():
    start_http_server(8000)


@huey.task(expires=15)
def handle_tick(tick: Tick, url: str):
    with HANDLE_TICK_PROCESSING_TIME.labels(url=url).time(), FEEDS_IN_PROGRESS.labels(
        url=url
    ).track_inprogress():
        r = random.random()
        print(tick.dt.isoformat(), url, r)
        time.sleep(r)
        print("INCREMENTING NOW")
        FEEDS_DOWNLOADED.labels(url=url).inc()
        print("INCREMENTING DONE")
    print("I AM NOW OUT OF THE CONTEXT MANAGER")


# @huey.periodic_task(crontab())
def three_ticks():
    now = pendulum.now()
    print(now)
    for delay in range(0, 41, 20):
        handle_tick.schedule(
            args=[Tick(dt=now + pendulum.duration(seconds=delay))], delay=delay
        )


# from celery import Celery

# app = Celery("tasks", broker="redis://localhost:6379/0")
# app.conf.task_serializer = "pickle"
# app.conf.result_serializer = "pickle"
# app.conf.accept_content = ["application/json", "application/x-python-serialize"]


# @app.task
# def print_tick(tick: Tick, url: str):
#     print(tick, url)
