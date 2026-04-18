import logging
import os
import sys
from concurrent.futures import ThreadPoolExecutor, TimeoutError

import google.cloud.logging
from google.cloud import pubsub_v1
from gtfs_rt_archiver.service import Service


class LogLevelFilter(logging.Filter):
    def filter(self, rec):
        return rec.levelno in (logging.DEBUG, logging.INFO)


logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)

stdout_handler = logging.StreamHandler(sys.stdout)
stdout_handler.setLevel(logging.DEBUG)
stdout_handler.addFilter(LogLevelFilter())
logger.addHandler(stdout_handler)

stderr_handler = logging.StreamHandler()
stderr_handler.setLevel(logging.WARNING)

logger.addHandler(stderr_handler)
client = google.cloud.logging.Client()
client.setup_logging()


def callback(message: pubsub_v1.subscriber.message.Message):
    Service(
        data=message.data.decode("utf-8"),
        publish_time=message.publish_time,
        message_id=message.message_id,
    ).run(logger=logger)
    message.ack()


if __name__ == "__main__":
    subscriber = pubsub_v1.SubscriberClient()

    scheduler = pubsub_v1.subscriber.scheduler.ThreadScheduler(
        executor=ThreadPoolExecutor(
            max_workers=int(os.environ.get("THREAD_POOL_SIZE", "150"))
        )
    )

    streaming_pull_future = subscriber.subscribe(
        os.environ["GTFS_RT_ARCHIVER__SUBSCRIPTION"],
        callback=callback,
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
