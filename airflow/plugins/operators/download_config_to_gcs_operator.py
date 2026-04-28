import json
import logging
import os
from email.message import Message
from typing import Sequence

from hooks.download_config_hook import DownloadConfigHook

from airflow.exceptions import AirflowException
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


class Download:
    hook: DownloadConfigHook
    exception: Exception
    current_time: str

    def __init__(self, hook: DownloadConfigHook, current_time: str) -> None:
        self.hook = hook
        self.exception = None
        self.current_time = current_time
        self._response = None

    def response(self):
        if not self._response and not self.exception:
            try:
                self._response = self.hook.run()
            except Exception as e:
                logging.error(e)
                self.exception = e
        return self._response

    def response_code(self) -> int | None:
        if self.response() is not None:
            return self.response().status_code
        else:
            return None

    def response_headers(self) -> int | None:
        if self.response() is not None:
            return self.response().headers
        else:
            return {}

    def success(self) -> bool:
        return self.response() is not None

    def content(self) -> str:
        return self.response().content

    def mime_type(self) -> str:
        return self.response_headers().get("Content-Type", "application/octet-stream")

    def filename(self) -> str:
        content_disposition = self.response_headers().get(
            "Content-Disposition", "attachment"
        )
        msg = Message()
        msg["content-disposition"] = content_disposition
        filename = msg.get_filename()

        if not filename and self.response() and self.response().url.endswith(".zip"):
            filename = os.path.basename(self.response().url)

        return filename if filename else "gtfs.zip"

    def extract(self) -> dict:
        return {
            "reconstructed": False,
            "ts": self.current_time,
            "filename": self.filename(),
            "config": self.hook.download_config,
            "response_code": self.response_code(),
            "response_headers": dict(self.response_headers()),
        }


class DownloadConfigToGCSOperator(BaseOperator):
    _download: Download
    _manual_download: ManualDownload
    _gcs_hook: GCSHook
    template_fields: Sequence[str] = (
        "dt",
        "ts",
        "base64_url",
        "download_config",
        "source_bucket",
        "source_path",
        "destination_bucket",
        "destination_path",
        "results_path",
        "gcp_conn_id",
    )

    def __init__(
        self,
        dt: str,
        ts: str,
        base64_url: str,
        download_config: dict,
        source_bucket: str,
        source_path: str,
        destination_bucket: str,
        destination_path: str,
        results_path: str,
        gcp_conn_id: str = "google_cloud_default",
        **kwargs,
    ) -> None:
        super().__init__(**kwargs)

        self._download: Download = None
        self._manual_download: ManualDownload = None
        self._gcs_hook: GCSHook = None
        self.dt: str = dt
        self.ts: str = ts
        self.base64_url: str = base64_url
        self.download_config: dict = download_config
        self.source_bucket: str = source_bucket
        self.source_path: str = source_path
        self.destination_bucket: str = destination_bucket
        self.destination_path: str = destination_path
        self.results_path: str = results_path
        self.gcp_conn_id: str = gcp_conn_id

    def destination_name(self) -> str:
        return self.destination_bucket.replace("gs://", "")

    def source_name(self) -> str:
        return self.source_bucket.replace("gs://", "")

    def gcs_hook(self) -> GCSHook:
        if self._gcs_hook is None:
            self._gcs_hook = GCSHook(gcp_conn_id=self.gcp_conn_id)
        return self._gcs_hook

    def download_config_hook(self) -> DownloadConfigHook:
        return DownloadConfigHook(download_config=self.download_config)

    def download(self) -> Download:
        if not self._download:
            self._download = Download(
                hook=self.download_config_hook(), current_time=self.ts
            )
        return self._download

    def manual_download(self) -> ManualDownload:
        if not self._manual_download:
            self._manual_download = ManualDownload(
                hook=self.gcs_hook(),
                bucket_name=self.source_name(),
                object_name=self.source_path,
                current_time=self.ts,
                download_config=self.download_config,
            )
        return self._manual_download

    def execute(self, context: Context) -> dict:
        ti = context["task_instance"]
        extract = self.download().extract()
        exception = (
            str(self.download().exception) if self.download().exception else None
        )
        schedule_feed_path = os.path.join(
            self.destination_path,
            self.download().filename(),
        )
        download_type = "Source URL"

        if self.download().success():
            self.gcs_hook().upload(
                bucket_name=self.destination_name(),
                object_name=schedule_feed_path,
                data=self.download().content(),
                mime_type=self.download().mime_type(),
                metadata={
                    "PARTITIONED_ARTIFACT_METADATA": json.dumps(
                        self.download().extract()
                    ),
                },
            )

        if (
            exception is not None and not ti.try_number - 1 == ti.max_tries
        ):  # last retry
            schedule_feed_path = os.path.join(
                self.destination_path,
                self.manual_download().filename(),
            )
            extract = self.manual_download().extract()
            exception = None
            download_type = "Manual Download"
            self.gcs_hook().upload(
                bucket_name=self.destination_name(),
                object_name=schedule_feed_path,
                data=self.manual_download().content(),
                mime_type=self.manual_download().mime_type(),
                metadata={
                    "PARTITIONED_ARTIFACT_METADATA": json.dumps(extract),
                },
            )

        download_schedule_feed_results = {
            "backfilled": False,
            "success": exception is None,
            "exception": exception,
            "config": self.download_config,
            "extract": extract,
            "download_type": download_type,
        }

        self.gcs_hook().upload(
            bucket_name=self.destination_name(),
            object_name=self.results_path,
            data=json.dumps(download_schedule_feed_results, separators=(",", ":")),
            mime_type="application/jsonl",
            gzip=False,
            metadata={
                "PARTITIONED_ARTIFACT_METADATA": json.dumps(
                    {
                        "filename": f"{self.base64_url}.jsonl",
                        "ts": self.ts,
                        "end": self.ts,
                        "backfilled": False,
                    }
                )
            },
        )

        if exception is not None:
            raise AirflowException(exception)

        return {
            "dt": self.dt,
            "ts": self.ts,
            "base64_url": self.base64_url,
            "schedule_feed_path": schedule_feed_path,
            "download_schedule_feed_results": download_schedule_feed_results,
        }
