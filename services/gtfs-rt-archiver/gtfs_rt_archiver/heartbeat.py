import datetime
import gzip
import json
import logging
import os
import traceback
from typing import Callable

from google.auth import default
from google.cloud import pubsub_v1, storage

PUBLISH_TIMEOUT = int(os.environ.get("PUBLISH_TIMEOUT", "10"))
GTFS_RT_FEED_TYPES = ["service_alerts", "trip_updates", "vehicle_positions"]


class Heartbeat:
    def future_callback(
        self, logger: logging.Logger
    ) -> Callable[[pubsub_v1.publisher.futures.Future], None]:
        def callback(publish_future: pubsub_v1.publisher.futures.Future) -> None:
            logger.info(
                json.dumps(
                    {
                        "severity": "Default",
                        "message": "Started",
                        "message_id": self.message_id,
                        "publish_time": self.publish_time.isoformat(),
                        "batch_at": self.batch_at().isoformat(),
                    }
                )
            )
            try:
                result = publish_future.result(timeout=PUBLISH_TIMEOUT)
                logger.info(
                    json.dumps(
                        {
                            "severity": "Default",
                            "message": f"Finished - {result}",
                            "message_id": self.message_id,
                            "publish_time": self.publish_time.isoformat(),
                            "batch_at": self.batch_at().isoformat(),
                        }
                    )
                )
            except Exception as e:
                logger.error(
                    json.dumps(
                        {
                            "severity": "Error",
                            "message": f"Failed - {e}",
                            "message_id": self.message_id,
                            "traceback": traceback.format_exc(),
                            "publish_time": self.publish_time.isoformat(),
                            "batch_at": self.batch_at().isoformat(),
                        }
                    )
                )

        return callback

    def __init__(
        self,
        data: str,
        publish_time: datetime.datetime,
        message_id: str,
        limit: int = None,
    ) -> None:
        self.data: str = data
        self.publish_time: datetime = publish_time
        self.message_id: str = message_id
        self.limit: int = limit

    def batch_at(self) -> datetime.datetime:
        return datetime.datetime.fromisoformat(json.loads(self.data)["batch_at"])

    def project_id(self) -> str:
        _, project_id = default()
        return project_id

    def bucket_name(self) -> str:
        return os.environ["CALITP_BUCKET__GTFS_DOWNLOAD_CONFIG"].removeprefix("gs://")

    def topic_name(self) -> str:
        return os.environ["CALITP_TOPIC__GTFS_RT_ARCHIVER"]

    def storage_client(self) -> storage.Client:
        return storage.Client()

    def match_glob(self) -> str:
        dates = [
            self.batch_at().date() - datetime.timedelta(days=days)
            for days in range(0, 5)
        ]
        pattern = "{" + ",".join([d.isoformat() for d in dates]) + "}"
        return f"gtfs_download_configs/dt={pattern}/**"

    def blob(self) -> storage.Blob:
        return sorted(
            self.storage_client().list_blobs(
                self.bucket_name(), match_glob=self.match_glob()
            ),
            key=lambda b: b.name,
        )[-1]

    def download_configs(self) -> list[str]:
        decompressed_result = gzip.decompress(self.blob().download_as_bytes())
        return [
            json.loads(download_config)
            for download_config in decompressed_result.decode().split("\n")
        ]

    def messages(self) -> list[str]:
        return [
            json.dumps(download_config, separators=(",", ":")).encode()
            for download_config in self.download_configs()
            if download_config["feed_type"] in GTFS_RT_FEED_TYPES
        ][slice(0, self.limit)]

    def run(
        self, publisher=pubsub_v1.PublisherClient()
    ) -> list[pubsub_v1.publisher.futures.Future]:
        return [
            publisher.publish(self.topic_name(), data=message)
            for message in self.messages()
        ]
