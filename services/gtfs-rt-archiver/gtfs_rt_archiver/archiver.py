import json
import os
import threading

from google.cloud.storage import Bucket, Client
from gtfs_rt_archiver.configuration import Configuration
from gtfs_rt_archiver.downloader import Result

# One GCS client per warm instance. It only ever talks to our own bucket with
# this service's credentials (fetched once from the metadata server, then cached
# and auto-refreshed), so reusing it across requests is safe and skips a
# per-fetch token round-trip. The lock is belt-and-suspenders in case request
# concurrency is ever raised above 1 (today it is 1, so there is no contention).
_client: Client | None = None
_client_lock = threading.Lock()


def shared_client() -> Client:
    global _client
    if _client is None:
        with _client_lock:
            if _client is None:
                _client = Client()
    return _client


class Archiver:
    def __init__(self, configuration: Configuration) -> None:
        self.configuration: Configuration = configuration

    def client(self) -> Client:
        return shared_client()

    def destination_bucket(self) -> str:
        return self.configuration.destination_bucket.replace("gs://", "")

    def bucket(self) -> Bucket:
        return self.client().bucket(bucket_name=self.destination_bucket())

    def save(self, result: Result) -> None:
        blob = self.bucket().blob(
            blob_name=os.path.join(
                self.configuration.destination_prefix(), result.filename()
            )
        )
        blob.metadata = {
            "PARTITIONED_ARTIFACT_METADATA": json.dumps(
                result.metadata(), separators=(",", ":")
            )
        }
        # Enabled only on the high-frequency service, where a colliding path means
        # silent data loss and there is no bucket retention policy to turn it into
        # a visible failure. Left off in production, where benign Pub/Sub
        # redelivery legitimately rewrites the same object.
        options = {}
        if os.environ.get("CALITP_GTFS_RT_FAIL_ON_OVERWRITE") == "true":
            options["if_generation_match"] = 0

        blob.upload_from_string(
            result.content(),
            content_type=result.mime_type(),
            **options,
        )
