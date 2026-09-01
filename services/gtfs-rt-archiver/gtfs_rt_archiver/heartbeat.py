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

# Set only on the high-frequency heartbeat. Holds a JSON array of download config
# names -- JSON rather than a comma-separated string because these names come from
# Airtable free text and may themselves contain commas.
HIGH_FREQUENCY_COHORT = "CALITP_GTFS_RT_HIGH_FREQUENCY_COHORT"

_UNSET = object()


def normalize(value: str) -> str:
    # Collapse internal whitespace runs rather than just stripping, so a name
    # pasted out of Airtable with a doubled space still matches.
    return " ".join((value or "").split()).casefold()


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
        self._cohort = _UNSET

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

    def cohort(self) -> set[str] | None:
        """The high-frequency cohort, or None when this is the standard archiver.

        Three states, deliberately distinct:
          env var absent -> None      -- no filtering, production behavior
          env var "[]"   -> set()     -- fail closed, publish nothing
          env var a list -> {names}   -- publish only those feeds

        Failing closed on an empty list matters: treating "present but empty" as
        "no filter" would fan the entire feed list out on the high-frequency
        clock, a ~20x load spike against every agency in the system.
        """
        if self._cohort is _UNSET:
            raw = os.environ.get(HIGH_FREQUENCY_COHORT)
            if raw is None:
                self._cohort = None
            elif raw.strip():
                self._cohort = {normalize(name) for name in json.loads(raw)}
            else:
                self._cohort = set()
        return self._cohort

    def in_cohort(self, download_config: dict) -> bool:
        cohort = self.cohort()
        if cohort is None:
            return True
        return normalize(download_config.get("name")) in cohort

    def should_publish(self, feed_type: str) -> bool:
        # The cohort runs on its own clock, so the 5-minute service_alerts throttle
        # -- which assumes batch times land on 20-second boundaries -- must not
        # apply to it.
        if self.cohort() is not None:
            return True

        if feed_type != "service_alerts":
            return True

        batch_at = self.batch_at()
        return batch_at.minute % 5 == 0 and batch_at.second == 0

    def payload(self, download_config: dict) -> dict:
        if self.cohort() is None:
            return download_config
        return download_config | {"batch_at": self.batch_at().isoformat()}

    def warn_on_unmatched(self, download_configs: list[dict]) -> None:
        cohort = self.cohort()
        if not cohort:
            return

        matched = {normalize(config.get("name")) for config in download_configs}
        if missing := cohort - matched:
            logging.warning(
                json.dumps(
                    {
                        "severity": "Warning",
                        "message": f"High-frequency cohort matched no download config: {sorted(missing)}",
                        "message_id": self.message_id,
                    }
                )
            )

    def messages(self) -> list[str]:
        download_configs = self.download_configs()
        self.warn_on_unmatched(download_configs)

        return [
            json.dumps(self.payload(download_config), separators=(",", ":")).encode()
            for download_config in download_configs
            if download_config["feed_type"] in GTFS_RT_FEED_TYPES
            and self.in_cohort(download_config)
            and self.should_publish(download_config["feed_type"])
        ][slice(0, self.limit)]

    def run(
        self, publisher=pubsub_v1.PublisherClient()
    ) -> list[pubsub_v1.publisher.futures.Future]:
        return [
            publisher.publish(self.topic_name(), data=message)
            for message in self.messages()
        ]
