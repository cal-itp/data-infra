import json
import logging
import os
from base64 import urlsafe_b64encode
from email.message import Message
from typing import Sequence

from hooks.download_config_hook import DownloadConfigHook

from airflow.models import BaseOperator
from airflow.models.taskinstance import Context
from airflow.providers.google.cloud.hooks.gcs import GCSHook


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

    def base64_url(self) -> str:
        return urlsafe_b64encode(self.hook.url().encode()).decode()

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

    def summary(self) -> dict:
        return {
            "backfilled": False,
            "success": self.success(),
            "exception": str(self.exception) if self.exception else None,
            "config": self.hook.download_config,
            "extract": self.extract(),
        }


class DownloadConfigToGCSOperator(BaseOperator):
    _download: Download
    template_fields: Sequence[str] = (
        "dt",
        "ts",
        "download_config",
        "destination_bucket",
        "destination_path",
        "results_path",
        "gcp_conn_id",
    )

    def __init__(
        self,
        dt: str,
        ts: str,
        download_config: dict,
        destination_bucket: str,
        destination_path: str,
        results_path: str,
        gcp_conn_id: str = "google_cloud_default",
        **kwargs,
    ) -> None:
        super().__init__(**kwargs)

        self._download: Download = None
        self.dt: str = dt
        self.ts: str = ts
        self.download_config: dict = download_config
        self.destination_bucket: str = destination_bucket
        self.destination_path: str = destination_path
        self.results_path: str = results_path
        self.gcp_conn_id: str = gcp_conn_id

    def destination_name(self) -> str:
        return self.destination_bucket.replace("gs://", "")

    def gcs_hook(self) -> GCSHook:
        return GCSHook(gcp_conn_id=self.gcp_conn_id)

    def download_config_hook(self) -> DownloadConfigHook:
        return DownloadConfigHook(download_config=self.download_config)

    def download(self) -> dict:
        if not self._download:
            self._download = Download(
                hook=self.download_config_hook(), current_time=self.ts
            )
        return self._download

    def execute(self, context: Context) -> dict:
        ti = context["task_instance"]
        last_retry = ti.try_number - 1 == ti.max_tries
        logging.info(
            f"Max tries: {ti.max_tries}, Try number: {ti.try_number}, Last retry: {last_retry}"
        )
        schedule_feed_path = f"{self.destination_path}/base64_url={self.download().base64_url()}/{self.download().filename()}"

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

        if not self.download().success() and not last_retry:
            raise self.download().exception

        download_schedule_feed_results = self.download().summary()

        self.gcs_hook().upload(
            bucket_name=self.destination_name(),
            object_name=f"{self.results_path}/{self.download().base64_url()}.jsonl",
            data=json.dumps(download_schedule_feed_results, separators=(",", ":")),
            mime_type="application/jsonl",
            gzip=False,
            metadata={
                "PARTITIONED_ARTIFACT_METADATA": json.dumps(
                    {
                        "filename": f"{self.download().base64_url()}.jsonl",
                        "ts": self.ts,
                        "end": self.ts,
                        "backfilled": False,
                    }
                )
            },
        )

        if not self.download().success():
            raise self.download().exception

        return {
            "dt": self.dt,
            "ts": self.ts,
            "base64_url": self.download().base64_url(),
            "schedule_feed_path": schedule_feed_path,
            "download_schedule_feed_results": download_schedule_feed_results,
        }
