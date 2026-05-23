import os
from typing import Sequence

from airflow.models import BaseOperator
from airflow.models.taskinstance import Context
from airflow.providers.google.cloud.hooks.bigquery import BigQueryHook
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class BigQueryToDictOperator(BaseOperator):
    template_fields: Sequence[str] = (
        "dataset_name",
        "table_name",
        "select_columns",
        "filter_date_column",
        "filter_date_start",
        "filter_date_end",
        "order_columns",
        "gcp_conn_id",
    )

    def __init__(
        self,
        dataset_name: str,
        table_name: str,
        select_columns: list[str],
        filter_date_column: str,
        filter_date_start: str,
        filter_date_end: str,
        order_columns: str,
        gcp_conn_id: str = "google_cloud_default",
        **kwargs,
    ) -> None:
        super().__init__(**kwargs)

        self._gcs_hook = None
        self._big_query_hook = None
        self.dataset_name: str = dataset_name
        self.table_name: str = table_name
        self.select_columns: list[str] = select_columns
        self.filter_date_column: str = filter_date_column
        self.filter_date_start: str = filter_date_start
        self.filter_date_end: str = filter_date_end
        self.order_columns: str = order_columns
        self.gcp_conn_id: str = gcp_conn_id

    def gcs_hook(self) -> GCSHook:
        if self._gcs_hook is None:
            self._gcs_hook = GCSHook(gcp_conn_id=self.gcp_conn_id)
        return self._gcs_hook

    def location(self) -> str:
        return os.getenv("CALITP_BQ_LOCATION")

    def bigquery_hook(self) -> BigQueryHook:
        if self._big_query_hook is None:
            self._big_query_hook = BigQueryHook(
                gcp_conn_id=self.gcp_conn_id,
                location=self.location(),
                use_legacy_sql=False,
            )
        return self._big_query_hook

    def rows(self) -> list[list[str]]:
        return self.bigquery_hook().get_records(
            sql=f"""
                SELECT {", ".join(self.select_columns)}
                FROM `{self.dataset_name}.{self.table_name}`
                WHERE {self.filter_date_column} BETWEEN CAST('{self.filter_date_start}' AS DATE) AND CAST('{self.filter_date_end}' AS DATE)
                ORDER BY {self.order_columns}
            """,
        )

    def execute(self, context: Context) -> list[dict]:
        return [dict(zip(self.select_columns, row)) for row in self.rows()]
