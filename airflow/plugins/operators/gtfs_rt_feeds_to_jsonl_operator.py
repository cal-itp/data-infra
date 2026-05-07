import json
import os
from datetime import datetime
from typing import Sequence

from hooks.gtfs_rt_feed_hook import GTFSRTFeedHook

from airflow.models import BaseOperator
from airflow.models.taskinstance import Context
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class GTFSRTFeedsToJSONLOperator(BaseOperator):
    template_fields: Sequence[str] = (
        "source_bucket",
        "source_paths",
        "destination_bucket",
        "destination_path",
        "results_path",
        "gcp_conn_id",
    )

    def __init__(
        self,
        source_bucket: str,
        source_paths: list[str],
        destination_bucket: str,
        destination_path: str,
        results_path: str,
        gcp_conn_id: str = "google_cloud_default",
        **kwargs,
    ) -> None:
        super().__init__(**kwargs)

        self.source_bucket: str = source_bucket
        self.source_paths: list[str] = source_paths
        self.destination_bucket: str = destination_bucket
        self.destination_path: str = destination_path
        self.results_path: str = results_path
        self.gcp_conn_id: str = gcp_conn_id
        self._results: list = None

    def gcs_hook(self) -> GCSHook:
        return GCSHook(gcp_conn_id=self.gcp_conn_id)

    def feed_hook(self) -> GTFSRTFeedHook:
        return GTFSRTFeedHook()

    def destination_name(self) -> str:
        return self.destination_bucket.replace("gs://", "")

    def source_name(self) -> str:
        return self.source_bucket.replace("gs://", "")

    def sources(self) -> bytes:
        if self._results is None:
            self._results = [
                self.feed_hook().parse(
                    object_name=self.destination_path,
                    source=self.gcs_hook().download(
                        bucket_name=self.source_name(),
                        object_name=source_path,
                    ),
                    metadata=self.gcs_hook().get_metadata(
                        bucket_name=self.source_name(),
                        object_name=source_path,
                    ),
                )
                for source_path in self.source_paths
            ]
        return self._results

    def data(self) -> list[dict]:
        return "\n".join(
            [
                json.dumps(entity, separators=(",", ":"))
                for source in self.sources()
                for entity in source.entities()
            ]
        )

    def results(self) -> list[dict]:
        return "\n".join(
            [
                json.dumps(
                    source.results(first_extract=self.sources()[0].parsed_metadata()),
                    separators=(",", ":"),
                )
                for source in self.sources()
            ]
        )

    def hour(self) -> datetime:
        datetime.fromisoformat(self.sources()[0].parsed_metadata()["ts"]).replace(
            minute=0, second=0, microsecond=0
        )

    def results_metadata(self) -> dict:
        return {
            "feed_type": self.sources()[0].parsed_metadata()["config"]["feed_type"],
            "filename": os.path.basename(self.results_path),
            "step": "parse",
            "hour": self.hour().isoformat(),
        }

    def execute(self, context: Context) -> str:
        self.gcs_hook().upload(
            bucket_name=self.destination_name(),
            object_name=self.destination_path,
            data=self.data(),
            mime_type="application/jsonl",
            gzip=True,
        )

        self.gcs_hook().upload(
            bucket_name=self.destination_name(),
            object_name=self.results_path,
            data=self.results(),
            mime_type="application/jsonl",
            metadata={
                "PARTITIONED_ARTIFACT_METADATA": json.dumps(
                    self.results_metadata(), separators=(",", ":")
                )
            },
        )

        return {
            "destination_path": self.destination_path,
            "results_path": self.results_path,
        }
