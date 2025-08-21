from datetime import datetime
from typing import Sequence

from airflow.models import BaseOperator
from airflow.models.taskinstance import Context
from airflow.providers.google.cloud.transfers.gcs_to_gcs import GCSToGCSOperator


class ReplicateBucketDataOperator(BaseOperator):
    template_fields: Sequence[str] = (
        "origin_bucket",
        "destination_bucket",
        "source_name",
        "source_date",
    )

    def __init__(
        self,
        origin_bucket: str,
        destination_bucket: str,
        source_name: str,
        source_date: datetime,
        gcp_conn_id: str = "google_cloud_default",
        **kwargs,
    ) -> None:
        super().__init__(**kwargs)

        self.origin_bucket = origin_bucket
        self.destination_bucket = destination_bucket
        self.source_name = source_name
        self.source_date = source_date
        self.gcp_conn_id = gcp_conn_id

    def destination_bucket_name(self) -> str:
        return self.destination_bucket.replace("gs://", "")

    def origin_bucket_name(self) -> str:
        return self.origin_bucket.replace("gs://", "")

    def origin_path(self) -> str:
        # Copy all objects from the source and specific date
        return f"{self.source_name}/dt={self.source_date.date().isoformat()}/*"

    def execute(self, context: Context) -> str:
        if self.origin_bucket_name and self.destination_bucket_name and self.source_name:
            print(f"Copy requested from bucket {self.origin_bucket_name}, path {self.origin_path} to bucket: {self.destination_bucket_name}")

            # task_id=f"replicate_bucket_data_{self.origin_bucket_name}",
            replicate_bucket = GCSToGCSOperator(
                task_id="replicate_bucket_data",
                source_bucket=self.origin_bucket_name,
                source_object=self.origin_path,
                destination_bucket=self.destination_bucket_name,
                replace=False,
                match_glob=True,
            )

            return replicate_bucket
            # return os.path.join(self.origin_bucket_name, self.origin_path)
        else:
            print(f"Invalid params origin bucket: {self.origin_bucket_name}, origin path {self.origin_path} to destination bucket: {self.destination_bucket_name}")

            return "Nope"
