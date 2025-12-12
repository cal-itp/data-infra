import json
import os
from typing import Sequence

from airflow.models import BaseOperator, DagRun
from airflow.models.taskinstance import Context
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class GCSToGTFSDownloadOperator(BaseOperator):
    template_fields: Sequence[str] = (
        "source_bucket",
        "source_path",
        "gcp_conn_id",
    )

    def __init__(
        self,
        source_bucket: str,
        source_path: str,
        gcp_conn_id: str = "google_cloud_default",
        **kwargs,
    ) -> None:
        super().__init__(**kwargs)
        self.source_bucket = source_bucket
        self.source_path = source_path
        self.gcp_conn_id = gcp_conn_id

    def gcs_hook(self) -> GCSHook:
        return GCSHook(gcp_conn_id=self.gcp_conn_id)

    def base64_url(self) -> str:
        return os.path.splitext(os.path.basename(self.source_path))[0]

    def source(self) -> bytes:
        results = self.gcs_hook().download(
            bucket_name=self.source_bucket.removeprefix("gs://"),
            object_name=self.source_path,
        )
        return json.loads(results.decode())

    def execute(self, context: Context) -> dict[str, str | dict]:
        dag_run: DagRun = context["dag_run"]
        results = self.source()
        if results["success"]:
            return {
                "base64_url": self.base64_url(),
                "download_schedule_feed_results": results,
                "schedule_feed_path": os.path.join(
                    "schedule",
                    f"dt={dag_run.logical_date.date().isoformat()}",
                    f"ts={dag_run.logical_date.isoformat()}",
                    f"base64_url={self.base64_url()}",
                    results.get("extract").get("filename"),
                ),
            }
