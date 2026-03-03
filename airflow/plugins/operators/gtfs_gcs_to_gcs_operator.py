import json
import os
from typing import Sequence

from airflow.exceptions import AirflowSkipException
from airflow.models import BaseOperator
from airflow.models.taskinstance import Context
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class ManualDownload:
    hook: GCSHook
    current_time: str
    bucket_name: str
    object_name: str
    download_config: dict

    def __init__(
        self,
        hook: GCSHook,
        bucket_name: str,
        object_name: str,
        current_time: str,
        download_config: dict,
    ) -> None:
        self.hook = hook
        self.current_time = current_time
        self.bucket_name = bucket_name
        self.object_name = object_name
        self.download_config = download_config

    def exists(self) -> bool:
        return self.hook.exists(
            bucket_name=self.bucket_name, object_name=self.object_name
        )

    def content(self) -> str:
        return self.hook.download(
            bucket_name=self.bucket_name, object_name=self.object_name
        )

    def mime_type(self) -> str:
        return "application/zip"

    def filename(self) -> str:
        return "gtfs.zip"

    def extract(self) -> dict:
        return {
            "reconstructed": False,
            "ts": self.current_time,
            "filename": self.filename(),
            "config": self.download_config,
            "response_code": 200,
            "response_headers": {
                "Content-Type": "application/zip",
                "Content-Disposition": "attachment; filename=gtfs.zip",
            },
        }


class GTFSGCSToGCSOperator(BaseOperator):
    _download: ManualDownload
    _gcs_hook: GCSHook
    template_fields: Sequence[str] = (
        "download_config",
        "source_bucket",
        "source_path",
        "destination_bucket",
        "destination_path",
        "gcp_conn_id",
    )

    def __init__(
        self,
        download_config: dict,
        ts: str,
        source_bucket: str,
        source_path: str,
        destination_bucket: str,
        destination_path: str,
        gcp_conn_id: str = "google_cloud_default",
        **kwargs,
    ) -> None:
        super().__init__(**kwargs)

        self._gcs_hook: GCSHook = None
        self._download: ManualDownload = None
        self.ts = ts
        self.download_config: dict = download_config
        self.source_bucket: str = source_bucket
        self.source_path: str = source_path
        self.destination_bucket: str = destination_bucket
        self.destination_path: str = destination_path
        self.gcp_conn_id: str = gcp_conn_id

    def destination_name(self) -> str:
        return self.destination_bucket.replace("gs://", "")

    def source_name(self) -> str:
        return self.source_bucket.replace("gs://", "")

    def gcs_hook(self) -> GCSHook:
        if self._gcs_hook is None:
            self._gcs_hook = GCSHook(gcp_conn_id=self.gcp_conn_id)
        return self._gcs_hook

    def manual_download(self) -> ManualDownload:
        if not self._download:
            self._download = ManualDownload(
                hook=self.gcs_hook(),
                bucket_name=self.source_name(),
                object_name=self.source_path,
                current_time=self.ts,
                download_config=self.download_config,
            )
        return self._download

    def execute(self, context: Context) -> dict:
        if self.manual_download().exists():
            schedule_feed_path = os.path.join(
                self.destination_path, self.manual_download().filename()
            )
            self.gcs_hook().upload(
                bucket_name=self.destination_name(),
                object_name=schedule_feed_path,
                data=self.manual_download().content(),
                mime_type=self.manual_download().mime_type(),
                metadata={
                    "PARTITIONED_ARTIFACT_METADATA": json.dumps(
                        self.manual_download().extract()
                    ),
                },
            )

            return {
                "schedule_feed_path": schedule_feed_path,
                "extract": self.manual_download().extract(),
            }
        else:
            raise AirflowSkipException
