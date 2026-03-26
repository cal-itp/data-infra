import os
from typing import Any, Sequence

from airflow.models import BaseOperator
from airflow.models.taskinstance import Context
from airflow.providers.google.cloud.hooks.bigquery import BigQueryHook


class BigQueryToAirtableIssuesOperator(BaseOperator):
    template_fields: Sequence[str] = (
        "dataset_name",
        "table_name",
        "columns",
        "gcp_conn_id",
    )

    def __init__(
        self,
        dataset_name: str,
        table_name: str,
        columns: list[str] | None = None,
        gcp_conn_id: str = "google_cloud_default",
        **kwargs,
    ) -> None:
        super().__init__(**kwargs)

        self.dataset_name = dataset_name
        self.table_name = table_name
        self.columns = columns or [
            "issue_number",
            "issue_source_record_id",
            "outreach_status",
            "gtfs_dataset_name",
            "new_end_date",
        ]
        self.gcp_conn_id = gcp_conn_id

    def location(self) -> str | None:
        return os.getenv("CALITP_BQ_LOCATION")

    def bigquery_hook(self) -> BigQueryHook:
        return BigQueryHook(
            gcp_conn_id=self.gcp_conn_id,
            location=self.location(),
            use_legacy_sql=False,
        )

    def rows(self) -> list[tuple[Any, ...]]:
        return self.bigquery_hook().get_records(
            sql=f"""
                SELECT {','.join(self.columns)}
                FROM `{self.dataset_name}.{self.table_name}`
            """
        )

    def execute(self, context: Context) -> list[dict[str, Any]]:
        return [dict(zip(self.columns, row)) for row in self.rows()]
