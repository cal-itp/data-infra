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
        "filter_column_name",
        "filter_value",
        "rows_limit",
        "gcp_conn_id",
    )

    def __init__(
        self,
        dataset_name: str,
        table_name: str,
        select_columns: list[str],
        filter_column_name: str,
        filter_value: str,
        rows_limit: int = 0,
        gcp_conn_id: str = "google_cloud_default",
        **kwargs,
    ) -> None:
        super().__init__(**kwargs)

        self._gcs_hook = None
        self._big_query_hook = None
        self.dataset_name: str = dataset_name
        self.table_name: str = table_name
        self.select_columns: list[str] = select_columns
        self.filter_column_name: str = filter_column_name
        self.filter_value: str = filter_value
        self.rows_limit: int = rows_limit
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

    def query(self) -> str:
        template = (
            "SELECT {columns}"
            " FROM `{dataset}.{table}`"
            " WHERE {filter_column} = {filter_value}"
            " {limit}"
        )
        limit = f"LIMIT {self.rows_limit}" if self.rows_limit > 0 else ""

        return template.format(
            columns=",".join(self.select_columns),
            dataset=self.dataset_name,
            table=self.table_name,
            filter_column=self.filter_column_name,
            filter_value=self.filter_value,
            limit=limit,
        )

    def rows(self) -> list[list[str]]:
        columns = (
            ", ".join(self.select_columns) if len(self.select_columns) > 0 else "*"
        )
        limit = f"LIMIT {self.rows_limit}" if self.rows_limit > 0 else ""
        return self.bigquery_hook().get_records(
            sql=f"SELECT {columns} FROM `{self.dataset_name}.{self.table_name}` WHERE {self.filter_column_name} = {self.filter_value} {limit}",
        )

    def execute(self, context: Context) -> str:
        return [dict(zip(self.select_columns, row)) for row in self.rows()]
        # return self.bigquery_hook().get_records(
        #     sql_results=self.rows(),
        #     as_dict=True,
        #     selected_fields=None
        # return self.rows()
