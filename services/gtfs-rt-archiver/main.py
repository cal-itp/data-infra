import json
import logging
import os
from concurrent.futures import TimeoutError
from datetime import datetime

from google.cloud import pubsub_v1
import google.cloud.logging as google_logging

from gtfs_rt_archiver.archiver import Archiver
from gtfs_rt_archiver.configuration import Configuration
from gtfs_rt_archiver.downloader import Downloader

logger = logging.getLogger(__name__)

class StreamingPullHandler:
    @staticmethod
    def run(message):
        StreamingPullHandler(message=message, current_time=datetime.now()).callback()

    def __init__(self, message: str, current_time: datetime):
        self.message: datetime = message
        self.current_time: datetime = current_time
        self._configuration = None

    def configuration(self):
        if not self._configuration:
            self._configuration = Configuration.resolve(
                published_time=self.current_time,
                **json.loads(self.message.data.decode("utf-8")),
            )
        return self._configuration

    def downloader(self):
        return Downloader(configuration=self.configuration())

    def archiver(self):
        return Archiver(configuration=self.configuration())

    def callback(self):
        try:
            logger.info(f"{self.configuration().url} - processing {self.message.data}")
            self.archiver().save(result=self.downloader().get())
        except Exception as e:
            logger.error(f"{self.configuration().url} - {e}")
        self.message.ack()


if __name__ == "__main__":
    google_logging.Client().setup_logging()

    subscriber = pubsub_v1.SubscriberClient()

    streaming_pull_future = subscriber.subscribe(
        os.environ["GTFS_RT_ARCHIVER__SUBSCRIPTION"], callback=StreamingPullHandler.run
    )

    with subscriber:
        try:
            streaming_pull_future.result()
        except TimeoutError:
            streaming_pull_future.cancel()
            streaming_pull_future.result()
        except Exception as e:
            logging.error(f"Streaming pull failed: {e}")
