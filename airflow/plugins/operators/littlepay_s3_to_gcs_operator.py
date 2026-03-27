import json
import os
from typing import Self, Sequence

from airflow.exceptions import AirflowSkipException
from airflow.models import BaseOperator
from airflow.models.taskinstance import Context
from airflow.providers.amazon.aws.hooks.s3 import S3Hook
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class PriorArtifact:
    @staticmethod
    def retrieve(
        gcs_hook: GCSHook, bucket_name: str, prefix: str, match_glob: str
    ) -> Self:
        prior_object_names = gcs_hook.list(
            bucket_name=bucket_name, prefix=prefix, match_glob=match_glob
        )
        recent_prior_object_names = sorted(
            prior_object_names,
            key=lambda object_name: gcs_hook.get_blob_update_time(
                bucket_name=bucket_name, object_name=object_name
            ),
            reverse=True,
        )
        if len(recent_prior_object_names) > 0:
            metadata = gcs_hook.get_metadata(
                bucket_name=bucket_name, object_name=recent_prior_object_names[0]
            )
            return PriorArtifact(
                bucket_name=bucket_name,
                object_name=recent_prior_object_names[0],
                metadata=metadata,
            )
        else:
            return PriorArtifact()

    def __init__(
        self, bucket_name: str = None, object_name: str = None, metadata: dict = {}
    ) -> None:
        self.bucket_name: str = bucket_name
        self.object_name: str = object_name
        self.metadata: dict = metadata

    def s3object_metadata(self) -> dict:
        if self.metadata is None:
            return {}

        return json.loads(self.metadata.get("PARTITIONED_ARTIFACT_METADATA", "{}")).get(
            "s3object", {}
        )


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
        self._source_object = None
        self._prior_artifact: PriorArtifact = None

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
        if self._source_object is None:
            self._source_object = (
                self.s3_hook()
                .get_key(bucket_name=self.source_bucket_name(), key=self.source_path)
                .get()
            )
        return self._source_object

    def source_etag(self) -> str:
        return self.source_object()["ETag"].replace('"', "")

    def metadata(self) -> dict:
        return {
            "filename": self.filename(),
            "instance": self.provider,
            "ts": self.ts,
            "s3bucket": self.source_bucket_name(),
            "s3object": {
                "Key": self.source_path,
                "LastModified": self.source_object()["LastModified"],
                "ETag": self.source_etag(),
                "Size": self.source_object()["ContentLength"],
                "StorageClass": self.source_object().get("StorageClass"),
            },
        }

    def prior_artifact(self) -> PriorArtifact:
        if self._prior_artifact is None:
            self._prior_artifact = PriorArtifact.retrieve(
                gcs_hook=self.gcs_hook(),
                bucket_name=self.destination_bucket_name(),
                prefix=self.destination_search_prefix,
                match_glob=self.destination_search_glob,
            )
        return self._prior_artifact

    def valid(self) -> bool:
        # return (
        #     self.prior_artifact().s3object_metadata() is None
        #     or self.source_object()["LastModified"]
        #     != self.prior_artifact().s3object_metadata().get("LastModified")
        #     or self.source_object()["ETag"]
        #     != self.prior_artifact().s3object_metadata().get("ETag")
        # )
        return (
            self.prior_artifact().s3object_metadata() is not None
            and str(self.source_object()["LastModified"])
            == self.prior_artifact().s3object_metadata().get("LastModified")
            and str(self.source_etag())
            == self.prior_artifact().s3object_metadata().get("ETag")
        )

    def execute(self, context: Context) -> dict:
        if self.valid():
            raise AirflowSkipException

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

        self.gcs_hook().upload(
            bucket_name=self.destination_bucket_name(),
            object_name=self.report_path,
            data=json.dumps(
                {
                    "success": True,
                    "exception": None,
                    "prior": self.prior_artifact().s3object_metadata(),
                    "extract": self.metadata(),
                },
                separators=(",", ":"),
                default=str,
            ),
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
            "filename": self.filename(),
            "filetype": self.filetype(),
            "destination_path": self.destination_path,
            "report_path": self.report_path,
        }
