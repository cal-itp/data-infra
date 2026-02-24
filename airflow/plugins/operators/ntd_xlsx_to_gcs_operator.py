from typing import Sequence

from hooks.ntd_xlsx_hook import NTDXLSXHook

from airflow.hooks.http_hook import HttpHook
from airflow.models import BaseOperator
from airflow.models.taskinstance import Context
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class NTDXLSXToGCSOperator(BaseOperator):
    template_fields: Sequence[str] = (
        "dt",
        "execution_ts",
        "type",
        "year",
        "source_url",
        "destination_bucket",
        "destination_path",
        "http_conn_id",
        "gcp_conn_id",
    )

    def __init__(
        self,
        dt: str,
        execution_ts: str,
        type: str,
        year: str,
        source_url: str,
        destination_bucket: str,
        destination_path: str,
        http_conn_id: str = "http_dot",
        gcp_conn_id: str = "google_cloud_default",
        **kwargs,
    ) -> None:
        super().__init__(**kwargs)

        self.dt: str = dt
        self.execution_ts: str = execution_ts
        self.type: str = type
        self.year: str = year
        self.source_url: str = source_url
        self.destination_bucket: str = destination_bucket
        self.destination_path: str = destination_path
        self.http_conn_id: str = http_conn_id
        self.gcp_conn_id: str = gcp_conn_id

    def destination_name(self) -> str:
        return self.destination_bucket.replace("gs://", "")

    def gcs_hook(self) -> GCSHook:
        return GCSHook(gcp_conn_id=self.gcp_conn_id)

    def ntd_xlsx_hook(self) -> NTDXLSXHook:
        return NTDXLSXHook(method="GET", http_conn_id=self.http_conn_id)

    def http_hook(self) -> NTDXLSXHook:
        return HttpHook(method="GET", http_conn_id=self.http_conn_id)

    def execute(self, context: Context) -> str:
        response = self.ntd_xlsx_hook().run(endpoint=self.source_url)
        self.gcs_hook().upload(
            data=response.content,
            bucket_name=self.destination_name(),
            object_name=self.destination_path,
            mime_type=response.headers.get("Content-Type"),
            gzip=False,
        )
        return {
            "destination_path": self.destination_path,
            "type": self.type,
            "year": self.year,
            "dt": self.dt,
            "execution_ts": self.execution_ts,
        }
