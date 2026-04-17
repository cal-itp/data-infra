import json
import os
import traceback
from concurrent.futures import TimeoutError
from datetime import datetime

from google.cloud import pubsub_v1
from gtfs_rt_archiver.archiver import Archiver
from gtfs_rt_archiver.configuration import Configuration
from gtfs_rt_archiver.downloader import Downloader
from gtfs_rt_archiver.logger import logger


class GtfsRtArchiver:
    @staticmethod
    def callback(message):
        GtfsRtArchiver(message=message, current_time=datetime.now()).run()

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

    def run(self):
        try:
            logger.debug(dir(self.message))
            logger.debug(self.message)
            logger.info(f"{self.configuration().url} - processing {self.message.data}")
            self.archiver().save(result=self.downloader().get())
        except Exception as e:
            logger.error(
                f"{self.configuration().url} - Caught error {e}\n{traceback.format_exc()}"
            )
        self.message.ack()


if __name__ == "__main__":
    subscriber = pubsub_v1.SubscriberClient()

    streaming_pull_future = subscriber.subscribe(
        os.environ["GTFS_RT_ARCHIVER__SUBSCRIPTION"], callback=GtfsRtArchiver.callback
    )

    with subscriber:
        try:
            streaming_pull_future.result()
        except TimeoutError as e:
            logger.error(f"Streaming pull timed out: {e}")
            streaming_pull_future.cancel()
            streaming_pull_future.result()
        except Exception as e:
            logger.error(f"Streaming pull failed: {e}")
