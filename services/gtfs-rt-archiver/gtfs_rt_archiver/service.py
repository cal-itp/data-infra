import datetime
import json
import logging
import traceback

from gtfs_rt_archiver.archiver import Archiver
from gtfs_rt_archiver.configuration import Configuration
from gtfs_rt_archiver.downloader import Downloader


class Service:
    def __init__(self, data: str, publish_time: datetime, message_id: str):
        self.data: str = data
        self.publish_time: datetime = publish_time
        self.message_id: str = message_id
        self._configuration = None

    def configuration(self):
        if not self._configuration:
            self._configuration = Configuration.resolve(
                publish_time=self.publish_time,
                **json.loads(self.data),
            )
        return self._configuration

    def downloader(self):
        return Downloader(configuration=self.configuration())

    def archiver(self):
        return Archiver(configuration=self.configuration())

    def run(self, logger=logging.getLogger(__name__)):
        # Per-fetch success logs are demoted to DEBUG: a successful fetch already
        # writes an object to the raw bucket (the success record), so these ~4M
        # INFO lines/day mostly duplicate it. Failures stay at ERROR below — a
        # failed fetch writes no object, so the log line is the only record. To
        # re-enable per-feed latency debugging, set LOG_LEVEL=DEBUG (see main.py).
        logger.debug(
            json.dumps(
                {
                    "severity": "Debug",
                    "message": f"Started {self.configuration().url}",
                    "url": self.configuration().url,
                    "message_id": self.message_id,
                    "publish_time": self.publish_time.isoformat(),
                }
            )
        )
        try:
            self.archiver().save(result=self.downloader().get())
            logger.debug(
                json.dumps(
                    {
                        "severity": "Debug",
                        "message": f"Finished {self.configuration().url}",
                        "url": self.configuration().url,
                        "message_id": self.message_id,
                        "publish_time": self.publish_time.isoformat(),
                    }
                )
            )
        except Exception as e:
            logger.error(
                json.dumps(
                    {
                        "severity": "Error",
                        "message": f"Failed {self.configuration().url} - {e}\n{traceback.format_exc()}",
                        "url": self.configuration().url,
                        "message_id": self.message_id,
                        "publish_time": self.publish_time.isoformat(),
                    }
                )
            )
