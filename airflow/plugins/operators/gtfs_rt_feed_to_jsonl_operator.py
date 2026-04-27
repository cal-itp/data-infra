import json
import logging
import os
from typing import Sequence

from airflow.models import BaseOperator
from airflow.models.taskinstance import Context
from airflow.providers.google.cloud.hooks.gcs import GCSHook
from google.protobuf import json_format
from google.transit import gtfs_realtime_pb2


class GTFSRTFeedToJSONLOperator(BaseOperator):
    template_fields: Sequence[str] = (
        "feed_type",
        "hour",
        "source_bucket",
        "source_path",
        "destination_bucket",
        "destination_path",
        "results_path",
        "gcp_conn_id",
    )

    def __init__(
        self,
        feed_type: str,
        hour: str,
        source_bucket: str,
        source_path: str,
        destination_bucket: str,
        destination_path: str,
        results_path: str,
        gcp_conn_id: str = "google_cloud_default",
        **kwargs,
    ) -> None:
        super().__init__(**kwargs)

        self.feed_type = feed_type
        self.hour = hour
        self.source_bucket = source_bucket
        self.source_path = source_path
        self.destination_bucket = destination_bucket
        self.destination_path = destination_path
        self.results_path = results_path
        self.gcp_conn_id = gcp_conn_id

    def gcs_hook(self) -> GCSHook:
        return GCSHook(gcp_conn_id=self.gcp_conn_id)

    def destination_name(self) -> str:
        return self.destination_bucket.replace("gs://", "")

    def source_name(self) -> str:
        return self.source_bucket.replace("gs://", "")

    def source(self) -> bytes:
        return self.gcs_hook().download(
            bucket_name=self.source_name(),
            object_name=self.source_path,
        )

    def source_json(self) -> str:
        feed = gtfs_realtime_pb2.FeedMessage()
        feed.ParseFromString(self.source())
        return json_format.MessageToDict(feed)

    def metadata(self) -> str:
        return {
            "filename": f"{self.feed_type}.jsonl",
            "step": "parse",
            "feed_type": self.feed_type,
            "hour": self.hour
        }

    def aggregation(self) -> str:
        return {
            "filename": f"{self.feed_type}.jsonl.gz",
            "step": "parse",
            "feed_type": self.feed_type,
            "hour": self.hour,
            "base64_url": self.base64_url,
        }


    def report(self) -> dict:
        {
            "success": False,
            "exception": "WARNING: no parsed entity found in gs://calitp-gtfs-rt-raw-v2/service_alerts/dt=2022-09-15/hour=2022-09-15T20:00:00+00:00/ts=2022-09-15T20:33:00+00:00/base64_url=aHR0cDovL2FwaS5iYXJ0Lmdvdi9ndGZzcnQvYWxlcnRzLmFzcHg=/feed",
            "extract": {
                "filename": "feed",
                "ts": "2022-09-15T20:33:00+00:00",
                "config": {
                    "extracted_at": "2022-09-15T14:58:59.865018+00:00",
                    "name": "BART Alerts",
                    "url": "http://api.bart.gov/gtfsrt/alerts.aspx",
                    "feed_type": "service_alerts",
                    "schedule_url_for_validation": "https://www.bart.gov/dev/schedules/google_transit.zip",
                    "auth_query_params": {},
                    "auth_headers": {}
                },
                "response_code": 200,
                "response_headers": {
                    "cache_control": "private",
                    "content_type": "text/html",
                    "content_encoding": "gzip",
                    "vary": "Accept-Encoding",
                    "server": "Microsoft-IIS/8.5",
                    "x_aspnet_version": "4.0.30319",
                    "x_powered_by": "ASP.NET",
                    "date": "Thu, 15 Sep 2022 20:33:00 GMT",
                    "content_length": "141"
                }
            },
            "aggregation": None,
            "blob_path": None
        }


    def execute(self, context: Context) -> str:
        self.gcs_hook().upload(
            bucket_name=self.destination_name(),
            object_name=self.destination_path,
            data=self.source_json(),
            mime_type="application/jsonl",
            gzip=True,
        )

        self.gcs_hook().upload(
            bucket_name=self.destination_name(),
            object_name=self.results_path,
            data=json.dumps(self.report(), separators=(",", ":")),
            mime_type="application/jsonl",
            gzip=False,
            metadata={
                "PARTITIONED_ARTIFACT_METADATA": json.dumps(self.metadata())
            },
        )

        return output
