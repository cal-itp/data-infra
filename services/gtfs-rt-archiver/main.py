import json
import os
import traceback
from concurrent.futures import TimeoutError

from google.cloud import pubsub_v1
from gtfs_rt_archiver.archiver import Archiver
from gtfs_rt_archiver.configuration import Configuration
from gtfs_rt_archiver.downloader import Downloader
from gtfs_rt_archiver.logger import logger


class GtfsRtArchiver:
    @staticmethod
    def callback(message):
        GtfsRtArchiver(message=message).run()

    def __init__(self, message: pubsub_v1.subscriber.message.Message):
        self.message: pubsub_v1.subscriber.message.Message = message
        self._configuration = None

    def configuration(self):
        if not self._configuration:
            self._configuration = Configuration.resolve(
                published_time=self.message.publish_time,
                **json.loads(self.message.data.decode("utf-8")),
            )
        return self._configuration

    def downloader(self):
        return Downloader(configuration=self.configuration())

    def archiver(self):
        return Archiver(configuration=self.configuration())

    def run(self):
        logger.info(f"{self.message.message_id} - {self.configuration().url}")
        try:
            self.archiver().save(result=self.downloader().get())
            logger.info(f"{self.message.message_id} - Processed")
        except Exception as e:
            logger.error(
                f"{self.message.message_id} - Caught error {e}\n{traceback.format_exc()}"
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
