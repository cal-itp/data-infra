import logging
from io import StringIO
from typing import Sequence

from hooks.ckan_hook import CKANHook

from airflow.models import BaseOperator
from airflow.models.taskinstance import Context
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class GCSToCKANOperator(BaseOperator):
    template_fields: Sequence[str] = (
        "dataset_id",
        "resource_name",
        "bucket_name",
        "object_name",
        "ckan_conn_id",
        "gcp_conn_id",
    )

    def __init__(
        self,
        dataset_id: str,
        resource_name: str,
        bucket_name: str,
        object_name: str,
        ckan_conn_id: str = "ckan_default",
        gcp_conn_id: str = "google_cloud_default",
        **kwargs,
    ) -> None:
        super().__init__(**kwargs)

        self.dataset_id = dataset_id
        self.resource_name = resource_name
        self.bucket_name = bucket_name
        self.object_name = object_name
        self.gcp_conn_id = gcp_conn_id
        self.ckan_conn_id = ckan_conn_id

    def gcs_hook(self) -> GCSHook:
        return GCSHook(gcp_conn_id=self.gcp_conn_id)

    def ckan_hook(self) -> CKANHook:
        return CKANHook(ckan_conn_id=self.ckan_conn_id)

    def resource_id(self) -> str:
        return self.ckan_hook().find_resource_id(
            dataset_id=self.dataset_id,
            resource_name=self.resource_name,
        )

    def upload(self):
        csv_file_names = self.gcs_hook().list(
            bucket_name=self.bucket_name.replace("gs://", ""), prefix=self.object_name
        )
        logging.info(
            f"Found {len(csv_file_names)} files in: {self.bucket_name}/{self.object_name}"
        )
        assert len(csv_file_names) > 0

        with CKANHook(
            ckan_conn_id=self.ckan_conn_id,
            resource_id=self.resource_id(),
            file_name=f"{self.resource_name}.csv",
        ) as ckan:
            for i, file_name in enumerate(csv_file_names):
                data = self.gcs_hook().download(
                    bucket_name=self.bucket_name.replace("gs://", ""),
                    object_name=file_name,
                )
                file = StringIO(data.decode())
                if i > 0:
                    next(file)
                result = ckan.multi_upload(file=file)
                logging.info(f"Uploaded: {file_name} as {result}")

    def execute(self, context: Context) -> dict[str, str | bool | int | float]:
        logging.info(f"Publishing {self.resource_name}...")
        self.upload()
        return {"result": True}
