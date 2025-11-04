import gzip
import json
import os
from datetime import datetime
from typing import Sequence

from airflow.models import BaseOperator, DagRun
from airflow.models.taskinstance import Context
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class DownloadConfigTransformer:
    def __init__(self, gtfs_dataset: dict[str, any]) -> None:
        self.gtfs_dataset = gtfs_dataset

    def feed_type(self) -> str:
        if "data" not in self.gtfs_dataset:
            return None
        elif "schedule" in self.gtfs_dataset["data"].lower():
            return "schedule"
        elif "vehicle" in self.gtfs_dataset["data"].lower():
            return "vehicle_positions"
        elif "trip" in self.gtfs_dataset["data"].lower():
            return "trip_updates"
        elif "alerts" in self.gtfs_dataset["data"].lower():
            return "service_alerts"
        else:
            return None

    def query_parameter(self) -> dict[str, str]:
        if (
            "authorization_url_parameter_name" in self.gtfs_dataset
            and "url_secret_key_name" in self.gtfs_dataset
        ):
            return {
                self.gtfs_dataset[
                    "authorization_url_parameter_name"
                ]: self.gtfs_dataset["url_secret_key_name"]
            }
        return {}

    def header(self) -> dict[str, str]:
        if (
            "authorization_header_parameter_name" in self.gtfs_dataset
            and "header_secret_key_name" in self.gtfs_dataset
        ):
            return {
                self.gtfs_dataset[
                    "authorization_header_parameter_name"
                ]: self.gtfs_dataset["header_secret_key_name"]
            }
        return {}

    def valid(self) -> bool:
        return self.feed_type() is not None

    def processable(self) -> bool:
        return self.gtfs_dataset["data_quality_pipeline"]

    def transform(self, date: pendulum.DateTime) -> dict[str, any]:
        return {
            "extracted_at": date.isoformat(),
            "name": self.gtfs_dataset["name"],
            "url": self.gtfs_dataset["uri"],
            "feed_type": self.feed_type(),
            "schedule_url_for_validation": self.gtfs_dataset["pipeline_url"],
            "computed": False,
            "auth_query_params": self.query_parameter(),
            "auth_headers": self.header(),
        }


class GTFSDatasetToDownloadConfigOperator(BaseOperator):
    _gcs_hook: GCSHook
    template_fields: Sequence[str] = (
        "source_bucket",
        "source_path",
        "destination_bucket",
        "destination_path",
        "gcp_conn_id",
    )

    def __init__(
        self,
        source_bucket: str,
        source_path: str,
        destination_bucket: str,
        destination_path: str,
        gcp_conn_id: str = "google_cloud_default",
        **kwargs,
    ) -> None:
        super().__init__(**kwargs)

        self._gcs_hook = None
        self.source_bucket = source_bucket
        self.source_path = source_path
        self.destination_bucket = destination_bucket
        self.destination_path = destination_path
        self.gcp_conn_id = gcp_conn_id

    def source_name(self) -> str:
        return self.source_bucket.replace("gs://", "")

    def destination_name(self) -> str:
        return self.destination_bucket.replace("gs://", "")

    def gcs_hook(self) -> GCSHook:
        return GCSHook(gcp_conn_id=self.gcp_conn_id)

    def cleaned_rows(self, date: pendulum.DateTime) -> list:
        compressed_result = self.gcs_hook().download(
            bucket_name=self.source_name(),
            object_name=self.source_path,
        )
        result = gzip.decompress(compressed_result)
        lines = result.decode().split("\n")
        dicts = [json.loads(l) for l in lines]
        transformers = [DownloadConfigTransformer(d) for d in dicts]
        valid_transformers = [t for t in transformers if t.valid() and t.processable()]
        blobs = [
            json.dumps(t.transform(date), separators=(",", ":"))
            for t in valid_transformers
        ]
        return "\n".join(blobs)

    def execute(self, context: Context) -> str:
        dag_run: DagRun = context["dag_run"]
        logical_date: pendulum.DateTime = pendulum.instance(dag_run.logical_date)
        self.gcs_hook().upload(
            bucket_name=self.destination_name(),
            object_name=self.destination_path,
            data=self.cleaned_rows(logical_date),
            mime_type="application/jsonl",
            gzip=True,
        )
        return os.path.join(self.destination_bucket, self.destination_path)
