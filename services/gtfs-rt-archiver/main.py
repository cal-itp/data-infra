import base64
import datetime
import logging

import functions_framework
import google.cloud.logging
from cloudevents.http.event import CloudEvent
from gtfs_rt_archiver.service import Service

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

client = google.cloud.logging.Client()
client.setup_logging()


@functions_framework.cloud_event
def process_cloud_event(cloud_event: CloudEvent) -> None:
    Service(
        data=base64.b64decode(cloud_event.data["message"]["data"]),
        publish_time=datetime.datetime.fromisoformat(
            cloud_event.data["message"]["publish_time"]
        ),
        message_id=cloud_event.data["message"]["message_id"],
    ).run(logger=logger)
