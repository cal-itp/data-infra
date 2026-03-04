import os
from typing import Sequence

from airflow.models import BaseOperator
from airflow.models.taskinstance import Context
from airflow.providers.amazon.aws.hooks.s3 import S3Hook
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class LittlepayS3ToGCSOperator(BaseOperator):
    template_fields: Sequence[str] = (
        "source_bucket",
        "source_path",
        "destination_bucket",
        "destination_path",
        "report_path",
        "aws_conn_id",
        "gcp_conn_id",
    )

    def __init__(
        self,
        source_bucket: str,
        source_path: str,
        destination_bucket: str,
        destination_path: str,
        report_path: str,
        aws_conn_id: str = "amazon_default",
        gcp_conn_id: str = "google_cloud_default",
        **kwargs,
    ) -> None:
        super().__init__(**kwargs)
        self.source_bucket: str = source_bucket
        self.source_path: str = source_path
        self.destination_bucket: str = destination_bucket
        self.destination_path: str = destination_path
        self.report_path: str = report_path
        self.aws_conn_id: str = aws_conn_id
        self.gcp_conn_id: str = gcp_conn_id

    def gcs_hook(self) -> GCSHook:
        return GCSHook(gcp_conn_id=self.gcp_conn_id)

    def s3_hook(self) -> S3Hook:
        return S3Hook(aws_conn_id=self.aws_conn_id)

    def source_name(self) -> str:
        return self.source_bucket.replace("gs://", "")

    def destination_name(self) -> str:
        return self.destination_bucket.replace("gs://", "")

    def filename(self) -> str:
        return os.path.basename(self.source_path)

    def filetype(self) -> str:
        return os.path.basename(os.path.dirname(self.source_path))

    def execute(self, context: Context) -> list[dict]:
        s3_object = self.s3_hook().get_key(
            bucket_name=self.source_name(), key=self.source_path
        )
        body = s3_object.get().get("Body")
        self.gcs_hook().upload(
            bucket_name=self.destination_name(),
            object_name=self.destination_path,
            data=body.read(),
            mime_type=s3_object.content_type,
        )
        return {
            "filename": self.filename(),
            "filetype": self.filetype(),
            "destination_path": self.destination_path,
            "report_path": self.report_path,
        }
