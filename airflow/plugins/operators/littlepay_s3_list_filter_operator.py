import json
import os

from airflow.models import BaseOperator
from airflow.providers.amazon.aws.hooks.s3 import S3Hook
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class LittlepayS3ListFilterOperator(BaseOperator):
    """List S3 files and return only files needing a GCS copy."""

    template_fields = (
        "source_bucket",
        "source_prefix",
        "provider",
        "destination_bucket",
    )

    def __init__(
        self,
        provider: str,
        source_bucket: str,
        source_prefix: str,
        destination_bucket: str,
        aws_conn_id: str = "amazon_default",
        gcp_conn_id: str = "google_cloud_default",
        **kwargs,
    ):
        super().__init__(**kwargs)
        self.provider = provider
        self.source_bucket = source_bucket
        self.source_prefix = source_prefix
        self.destination_bucket = destination_bucket
        self.aws_conn_id = aws_conn_id
        self.gcp_conn_id = gcp_conn_id

    def execute(self, context) -> list[str]:
        s3_hook = S3Hook(aws_conn_id=self.aws_conn_id)
        gcs_hook = GCSHook(gcp_conn_id=self.gcp_conn_id)
        bucket_name = self.destination_bucket.removeprefix("gs://")

        paginator = s3_hook.get_conn().get_paginator("list_objects_v2")

        source_objects = []
        for page in paginator.paginate(
            Bucket=self.source_bucket,
            Prefix=self.source_prefix,
        ):
            source_objects.extend(page.get("Contents", []))

        paths_to_copy = []

        for current_s3 in source_objects:
            source_path = current_s3["Key"]

            parts = source_path.split("/")
            if len(parts) < 3:
                paths_to_copy.append(source_path)
                continue

            entity = parts[2]
            filename = os.path.basename(source_path)
            prefix = f"{entity}/instance={self.provider}/filename={filename}"

            prior_objects = (
                gcs_hook.list(
                    bucket_name=bucket_name,
                    prefix=prefix,
                    match_glob=f"**/{filename}",
                )
                or []
            )

            if not prior_objects:
                paths_to_copy.append(source_path)
                continue

            latest_object = max(
                prior_objects,
                key=lambda name: gcs_hook.get_blob_update_time(
                    bucket_name=bucket_name,
                    object_name=name,
                ),
            )

            metadata = (
                gcs_hook.get_metadata(
                    bucket_name=bucket_name,
                    object_name=latest_object,
                )
                or {}
            )

            try:
                artifact_metadata = json.loads(
                    metadata.get("PARTITIONED_ARTIFACT_METADATA", "{}")
                )
                previous_s3 = artifact_metadata.get("s3object") or {}
            except (TypeError, ValueError, AttributeError):
                previous_s3 = {}

            changed = current_s3["LastModified"].isoformat() != previous_s3.get(
                "LastModified"
            ) or current_s3["ETag"] != previous_s3.get("ETag")

            if changed:
                paths_to_copy.append(source_path)

        self.log.info(
            "Littlepay provider %s: %d source files, %d to copy",
            self.provider,
            len(source_objects),
            len(paths_to_copy),
        )

        return paths_to_copy
