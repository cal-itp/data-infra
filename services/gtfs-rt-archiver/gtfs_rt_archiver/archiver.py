import json
import os

from google.cloud.storage import Bucket, Client
from gtfs_rt_archiver.configuration import Configuration
from gtfs_rt_archiver.downloader import Result


class Archiver:
    def __init__(self, configuration: Configuration) -> None:
        self.configuration: Configuration = configuration

    def client(self) -> Client:
        return Client()

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
        blob.upload_from_string(
            result.content(),
            content_type=result.mime_type(),
        )
