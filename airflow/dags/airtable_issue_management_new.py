import os
from datetime import datetime, timedelta

from operators.bigquery_to_airtable_issues_operator import (
    BigQueryToAirtableIssuesOperator,
)

from airflow import DAG
from airflow.operators.latest_only import LatestOnlyOperator

with DAG(
    dag_id="airtable_issue_management_new",
    tags=["airtable", "tdq", "automation"],
    # Every Friday at 6am PDT/7am PST (2pm UTC)
    schedule="0 2 * * 5",
    start_date=datetime(2026, 2, 25),
    catchup=False,
    default_args={
        "email": os.getenv("CALITP_NOTIFY_EMAIL"),
        "email_on_failure": True,
        "email_on_retry": False,
    },
):
    latest_only = LatestOnlyOperator(task_id="latest_only", depends_on_past=False)

    airtable_issues = BigQueryToAirtableIssuesOperator(
        task_id="bigquery_to_airtable_issues",
        retries=1,
        retry_delay=timedelta(seconds=10),
        dataset_name="mart_transit_database",
        table_name="fct_close_expired_issues",
    )
