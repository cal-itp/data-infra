import base64
from datetime import datetime
import json
import os
import logging
from concurrent.futures import TimeoutError

from google.cloud import pubsub_v1
from gtfs_rt_archiver.archiver import Archiver
from gtfs_rt_archiver.configuration import Configuration
from gtfs_rt_archiver.downloader import Downloader


logging.basicConfig(
    format="%(asctime)s - %(levelname)s - %(message)s"
)

class StreamingPullHandler:
    @staticmethod
    def run(message):
        logging.debug(f"Processing {message}")
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
            self.archiver().save(result=self.downloader().get())
            self.message.ack()
        except Exception as e:
            self.message.nack()
            logging.error(f"Processing {self.configuration().url} failed: {e} message")


if __name__ == "__main__":
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
