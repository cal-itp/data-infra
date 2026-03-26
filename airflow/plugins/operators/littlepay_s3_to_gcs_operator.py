import json
import os
from typing import Sequence

from airflow.models import BaseOperator
from airflow.models.taskinstance import Context
from airflow.providers.amazon.aws.hooks.s3 import S3Hook
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class LittlepayS3ToGCSOperator(BaseOperator):
    template_fields: Sequence[str] = (
        "ts",
        "provider",
        "source_bucket",
        "source_path",
        "destination_bucket",
        "destination_path",
        "destination_search_prefix",
        "destination_search_glob",
        "report_path",
        "aws_conn_id",
        "gcp_conn_id",
    )

    def __init__(
        self,
        ts: str,
        provider: str,
        source_bucket: str,
        source_path: str,
        destination_bucket: str,
        destination_path: str,
        destination_search_prefix: str,
        destination_search_glob: str,
        report_path: str,
        aws_conn_id: str = "amazon_default",
        gcp_conn_id: str = "google_cloud_default",
        **kwargs,
    ) -> None:
        super().__init__(**kwargs)
        self.ts: str = ts
        self.provider: str = provider
        self.source_bucket: str = source_bucket
        self.source_path: str = source_path
        self.destination_bucket: str = destination_bucket
        self.destination_path: str = destination_path
        self.destination_search_prefix: str = destination_search_prefix
        self.destination_search_glob: str = destination_search_glob
        self.report_path: str = report_path
        self.aws_conn_id: str = aws_conn_id
        self.gcp_conn_id: str = gcp_conn_id

    def gcs_hook(self) -> GCSHook:
        return GCSHook(gcp_conn_id=self.gcp_conn_id)

    def s3_hook(self) -> S3Hook:
        return S3Hook(aws_conn_id=self.aws_conn_id)

    def source_bucket_name(self) -> str:
        return self.source_bucket.replace("gs://", "")

    def destination_bucket_name(self) -> str:
        return self.destination_bucket.replace("gs://", "")

    def filename(self) -> str:
        return os.path.basename(self.source_path)

    def filetype(self) -> str:
        return os.path.basename(os.path.dirname(self.source_path))

    def source_object(self) -> any:
        return (
            self.s3_hook()
            .get_key(bucket_name=self.source_bucket_name(), key=self.source_path)
            .get()
        )

    def prior_destination_paths(self) -> list[str]:
        return self.gcs_hook().list(
            bucket_name=self.destination_bucket_name(),
            prefix=self.destination_search_prefix,
            match_glob=self.destination_search_glob,
        )

    def latest_destination_path(self) -> str:
        return sorted(
            self.prior_destination_paths(),
            key=lambda file_path: self.gcs_hook().get_blob_update_time(
                bucket_name=self.destination_bucket_name(), object_name=file_path
            ),
            reverse=True,
        )[0]

    def latest_destination_metadata(self) -> dict:
        return json.loads(
            self.gcs_hook()
            .get_metadata(
                bucket_name=self.destination_bucket_name(),
                object_name=self.latest_destination_path(),
            )
            .get("PARTITIONED_ARTIFACT_METADATA", "{}")
        ).get("s3object", {})

    def valid(self) -> bool:
        return (
            len(self.prior_destination_paths()) == 0
            or self.latest_destination_metadata() is None
            or self.source_object()["LastModified"]
            != self.latest_destination_metadata()["LastModified"]
            or self.source_object()["ETag"]
            != self.latest_destination_metadata()["ETag"]
        )

    def metadata(self) -> dict:
        return {
            "filename": self.filename(),
            "instance": self.provider,
            "ts": self.ts,
            "s3bucket": self.source_bucket_name(),
            "s3object": {
                "Key": self.source_path,
                "LastModified": self.source_object()["LastModified"],
                "ETag": self.source_object()["ETag"].replace('"', ""),
                "Size": self.source_object()["ContentLength"],
                "StorageClass": self.source_object().get("StorageClass"),
            },
        }

    def execute(self, context: Context) -> list[dict]:
        valid = self.valid()

        if valid:
            self.gcs_hook().upload(
                bucket_name=self.destination_bucket_name(),
                object_name=self.destination_path,
                data=self.source_object()["Body"].read(),
                mime_type=self.source_object()["ContentType"],
                gzip=False,
                metadata={
                    "PARTITIONED_ARTIFACT_METADATA": json.dumps(
                        self.metadata(), default=str
                    )
                },
            )

            report = {
                "success": True,
                "exception": None,
                "prior": self.latest_destination_metadata()
                if len(self.prior_destination_paths()) > 0
                else None,
                "extract": self.metadata(),
            }

            self.gcs_hook().upload(
                bucket_name=self.destination_bucket_name(),
                object_name=self.report_path,
                data=json.dumps(report, separators=(",", ":"), default=str),
                mime_type="application/jsonl",
                gzip=False,
                metadata={
                    "PARTITIONED_ARTIFACT_METADATA": json.dumps(
                        {
                            "filename": f"results_{self.filename()}.jsonl",
                            "instance": self.provider,
                            "ts": self.ts,
                        }
                    )
                },
            )

        return {
            "valid": valid,
            "filename": self.filename(),
            "filetype": self.filetype(),
            "destination_path": self.destination_path,
            "report_path": self.report_path,
        }
