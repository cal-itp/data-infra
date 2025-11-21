import gzip
import json
from typing import Sequence

from airflow.models import BaseOperator
from airflow.models.taskinstance import Context
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class GCSDownloadConfigFilterOperator(BaseOperator):
    template_fields: Sequence[str] = (
        "feed_type",
        "source_bucket",
        "source_path",
        "gcp_conn_id",
    )

    def __init__(
        self,
        feed_type: str,
        source_bucket: str,
        source_path: str,
        gcp_conn_id: str = "google_cloud_default",
        **kwargs,
    ) -> None:
        super().__init__(**kwargs)

        self._gcs_hook = None
        self.feed_type = feed_type
        self.source_bucket = source_bucket
        self.source_path = source_path
        self.gcp_conn_id = gcp_conn_id

    def gcs_hook(self) -> GCSHook:
        return GCSHook(gcp_conn_id=self.gcp_conn_id)

    def rows(self) -> list:
        data = self.gcs_hook().download(
            bucket_name=self.source_bucket.replace("gs://", ""),
            object_name=self.source_path,
        )
        return [json.loads(x) for x in gzip.decompress(data).splitlines()]

    def execute(self, context: Context) -> str:
        return [row for row in self.rows() if row["feed_type"] == self.feed_type]
