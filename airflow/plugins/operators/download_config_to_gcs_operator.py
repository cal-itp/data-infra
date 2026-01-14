import json
import logging
import os
from base64 import urlsafe_b64encode
from email.message import Message
from typing import Sequence

import pendulum
from hooks.download_config_hook import DownloadConfigHook

from airflow.models import BaseOperator, DagRun
from airflow.models.taskinstance import Context
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class RemoteFile:
    hook: DownloadConfigHook
    exception: Exception

    def __init__(self, hook: DownloadConfigHook) -> None:
        self.hook = hook
        self.exception = None
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

        if not filename and self.hook.url().endswith(".zip"):
            filename = os.path.basename(self.hook.url())

        return filename if filename else "gtfs.zip"

    def extract(self, current_time: pendulum.DateTime) -> dict:
        return {
            "reconstructed": False,
            "ts": current_time.isoformat(),
            "filename": self.filename(),
            "config": self.hook.download_config,
            "response_code": self.response_code(),
            "response_headers": dict(self.response_headers()),
        }

    def summary(self, current_time: pendulum.DateTime) -> dict:
        return {
            "backfilled": False,
            "success": self.success(),
            "exception": str(self.exception) if self.exception else None,
            "config": self.hook.download_config,
            "extract": self.extract(current_time=current_time),
        }


class BaseDownloadHandler:
    def __init__(self, download_config: dict) -> None:
        self.download_config = download_config

    def base64_url(self) -> str:
        return urlsafe_b64encode(self.download_config.get("url")).decode()

    def valid(self) -> bool:
        return True

    def downloadable(self) -> bool:
        return False

    def reportable(self) -> bool:
        return False

    def content(self) -> bytes:
        return b""

    def mime_type(self) -> str:
        return "application/octet-stream"

class DropboxDownloadHandler(BaseDownloadHandler):

class DownloadUrlHandler(BaseDownloadHandler):
    def download_config_hook(self) -> DownloadConfigHook:
        return DownloadConfigHook(download_config=self.download_config)

    def remote_file(self) -> str:
        if not self._remote_file
            self._remote_file = RemoteFile(hook=self.download_config_hook())
        return self._remote_file

    def path(self) -> str:
        return f"base64_url={self.base64_url()}/{self.remote_file().filename()}"

    def downloadable(self) -> bool:
        return True

    def content(self) -> bytes:
        return self.remote_file().content()

    def mime_type(self) -> str:
        return self.remote_file().mime_type()


        if self.gcs_hook().exists(
            bucket_name=self.destination_name(),
            object_name=f"{self.destination_path}/{self.download().schedule_feed_path()}",
        ):
            pass

        elif self.gcs_hook().exists(
            bucket_name=self.dropbox_name(),
            object_name=self.dropbox().schedule_feed_path(),
        ):
            schedule_feed = self.gcs_hook().download(
                bucket_name=self.dropbox_name(),
                object_name=self.dropbox_schedule_feed_path(),
            )

            self.gcs_hook().upload(
                bucket_name=self.destination_name(),
                object_name=self.schedule_feed_path(),
                data=schedule_feed,
                mime_type=self.download().mime_type(),
                metadata={
                    "PARTITIONED_ARTIFACT_METADATA": json.dumps(
                        self.download().extract(current_time=dag_run.logical_date)
                    ),
                },
            )

        else:
            if self.download().success():
                self.gcs_hook().upload(
                    bucket_name=self.destination_name(),
                    object_name=self.schedule_feed_path(),
                    data=self.download().content(),
                    mime_type=self.download().mime_type(),
                    metadata={
                        "PARTITIONED_ARTIFACT_METADATA": json.dumps(
                            self.download().extract(current_time=dag_run.logical_date)
                        ),
                    },
                )

            download_schedule_feed_results = self.download().summary(
                current_time=dag_run.logical_date
            )

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
                            "ts": dag_run.logical_date.isoformat(),
                            "end": dag_run.logical_date.isoformat(),
                            "backfilled": False,
                        }
                    )
                },
            )

            if not self.download().success():
                raise self.download().exception

        download_schedule_feed_results = self.gcs_hook().download(
            bucket_name=self.destination_name(),
            object_name=f"{self.results_path}/{self.download().base64_url()}.jsonl",
        )

        return {
            "base64_url": self.download().base64_url(),
            "schedule_feed_path": self.schedule_feed_path(),
            "download_schedule_feed_results": json.loads(
                download_schedule_feed_results
            ),
        }


class DownloadConfigToGCSOperator(BaseOperator):
    _download: Download
    template_fields: Sequence[str] = (
        "download_config",
        "destination_bucket",
        "destination_path",
        "results_path",
        "gcp_conn_id",
    )

    def __init__(
        self,
        download_config: dict,
        destination_bucket: str,
        destination_path: str,
        results_path: str,
        gcp_conn_id: str = "google_cloud_default",
        **kwargs,
    ) -> None:
        super().__init__(**kwargs)

        self._download: Download = None
        self.download_config: dict = download_config
        self.destination_bucket: str = destination_bucket
        self.destination_path: str = destination_path
        self.results_path: str = results_path
        self.gcp_conn_id: str = gcp_conn_id

    def destination_name(self) -> str:
        return self.destination_bucket.replace("gs://", "")

    def gcs_hook(self) -> GCSHook:
        return GCSHook(gcp_conn_id=self.gcp_conn_id)

    def strategy(self) -> DownloadHandler:
        if not self._strategy:
            self._strategy = filter([
                SkipDownloadHandler(download_config=self.download_config),
                DownloadDropboxHandler(download_config=self.download_config),
                DownloadHandler(download_config=self.download_config)
            ], lambda s: s.valid())
        return self._strategy

    def execute(self, context: Context) -> str:
        dag_run: DagRun = context["dag_run"]

        if self.strategy().downloadable():
            self.gcs_hook().upload(
                bucket_name=self.destination_name(),
                object_name=f"{self.destination_path}/{self.strategy().path()}",
                data=self.strategy().content(),
                mime_type=self.strategy().mime_type(),
                metadata={
                    "PARTITIONED_ARTIFACT_METADATA": json.dumps(
                        self.strategy().extract(current_time=dag_run.logical_date)
                    ),
                },
            )

        if self.strategy().reportable():
            self.gcs_hook().upload(
                bucket_name=self.destination_name(),
                object_name=f"{self.results_path}/{self.strategy().base64_url()}.jsonl",
                data=json.dumps(self.strategy().results(), separators=(",", ":")),
                mime_type="application/jsonl",
                gzip=False,
                metadata={
                    "PARTITIONED_ARTIFACT_METADATA": json.dumps(
                        {
                            "filename": f"{self.strategy().base64_url()}.jsonl",
                            "ts": dag_run.logical_date.isoformat(),
                            "end": dag_run.logical_date.isoformat(),
                            "backfilled": False,
                        }
                    )
                },
            )

        return {
            "base64_url": self.strategy().base64_url(),
            "schedule_feed_path": self.strategy().path(),
            "download_schedule_feed_results": self.strategy().results()
        }

