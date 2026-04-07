import base64
import json

import functions_framework
from cloudevents.http.event import CloudEvent
from gtfs_rt_archiver.archiver import Archiver
from gtfs_rt_archiver.configuration import Configuration
from gtfs_rt_archiver.downloader import Downloader


@functions_framework.cloud_event
def process_cloud_event(cloud_event: CloudEvent) -> None:
    configuration = Configuration.resolve(
        published_time=cloud_event.data["message"]["publish_time"],
        **json.loads(base64.b64decode(cloud_event.data["message"]["data"]))
    )
    downloader = Downloader(configuration=configuration)
    archiver = Archiver(configuration=configuration)
    archiver.save(result=downloader.get())
