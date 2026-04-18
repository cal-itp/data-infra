import json
import os
import traceback
from concurrent.futures import ThreadPoolExecutor, TimeoutError

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
        logger.info(
            json.dumps(
                {
                    "severity": "Default",
                    "message": f"Started {self.configuration().url}",
                    "url": self.configuration().url,
                    "message_id": self.message.message_id,
                    "published_time": self.message.publish_time,
                }
            )
        )
        try:
            self.archiver().save(result=self.downloader().get())
            logger.info(
                json.dumps(
                    {
                        "severity": "Default",
                        "message": f"Finished {self.configuration().url}",
                        "url": self.configuration().url,
                        "message_id": self.message.message_id,
                        "published_time": self.message.publish_time,
                    }
                )
            )
        except Exception as e:
            logger.error(
                json.dumps(
                    {
                        "severity": "Error",
                        "message": f"Failed {self.configuration().url} - {e}",
                        "url": self.configuration().url,
                        "message_id": self.message.message_id,
                        "traceback": traceback.format_exc(),
                        "published_time": self.message.publish_time,
                    }
                )
            )
        self.message.ack()


if __name__ == "__main__":
    subscriber = pubsub_v1.SubscriberClient()

    scheduler = pubsub_v1.subscriber.scheduler.ThreadScheduler(
        executor=ThreadPoolExecutor(
            max_workers=int(os.environ.get("THREAD_POOL_SIZE", "100"))
        )
    )

    streaming_pull_future = subscriber.subscribe(
        os.environ["GTFS_RT_ARCHIVER__SUBSCRIPTION"],
        callback=GtfsRtArchiver.callback,
        scheduler=scheduler,
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
