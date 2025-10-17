import logging
from io import StringIO
from typing import Sequence

import pandas as pd
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

    def build_csv(self):
        combined_data_stream = StringIO()
        header_written = False

        csv_file_names = self.gcs_hook().list(
            bucket_name=self.bucket_name.replace("gs://", ""), prefix=self.object_name
        )
        logging.info(
            f"Found {len(csv_file_names)} files in: {self.bucket_name}/{self.object_name}"
        )
        assert len(csv_file_names) > 0

        for file_name in csv_file_names:
            logging.info(f"Reading {self.bucket_name}/{file_name}")
            data = self.gcs_hook().download(
                bucket_name=self.bucket_name.replace("gs://", ""),
                object_name=file_name,
            )

            df = pd.read_csv(StringIO(data.decode()), sep="\t", dtype=str)

            if not header_written:
                df.to_csv(combined_data_stream, index=False)
                header_written = True
            else:
                df.to_csv(combined_data_stream, index=False, header=False)

        logging.info("Build success")
        return combined_data_stream.getvalue()

    def execute(self, context: Context) -> dict[str, str | bool | int | float]:
        logging.info(f"Publishing {self.resource_name}...")

        csv = self.build_csv()
        result = self.ckan_hook().upload(
            resource_id=self.resource_id(),
            file=csv,
        )
        logging.info(result)
        return result
