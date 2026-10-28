import base64
import datetime
import logging
from concurrent import futures

import functions_framework
import google.cloud.logging
from cloudevents.http.event import CloudEvent
from gtfs_rt_archiver.heartbeat import Heartbeat
from gtfs_rt_archiver.service import Service

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

client = google.cloud.logging.Client()
client.setup_logging()


@functions_framework.cloud_event
def process_clock_event(cloud_event: CloudEvent) -> None:
    clock = Heartbeat(
        data=base64.b64decode(cloud_event.data["message"]["data"]),
        publish_time=datetime.datetime.fromisoformat(
            cloud_event.data["message"]["publish_time"]
        ),
        message_id=cloud_event.data["message"]["message_id"],
    )
    publish_futures = clock.run()
    for publish_future in publish_futures:
        publish_future.add_done_callback(clock.future_callback(logger=logger))
    futures.wait(publish_futures, return_when=futures.ALL_COMPLETED)


@functions_framework.cloud_event
def process_heartbeat_event(cloud_event: CloudEvent) -> None:
    Service(
        data=base64.b64decode(cloud_event.data["message"]["data"]),
        publish_time=datetime.datetime.fromisoformat(
            cloud_event.data["message"]["publish_time"]
        ),
        message_id=cloud_event.data["message"]["message_id"],
    ).run(logger=logger)
