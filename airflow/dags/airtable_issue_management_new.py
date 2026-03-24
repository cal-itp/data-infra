from datetime import datetime, timedelta

import pendulum
from operators.airtable_issues_email_operator import AirtableIssuesEmailOperator
from operators.airtable_issues_update_operator import AirtableIssuesUpdateOperator
from operators.bigquery_to_airtable_issues_operator import (
    BigQueryToAirtableIssuesOperator,
)

from airflow import DAG

# from airflow.operators.latest_only import LatestOnlyOperator

local_tz = pendulum.timezone("America/Los_Angeles")

with DAG(
    dag_id="airtable_issue_management_new",
    tags=["airtable", "tdq", "automation"],
    schedule="0 6 * * 5",
    start_date=datetime(2026, 3, 27, tzinfo=local_tz),
    catchup=False,
    default_args={
        "email": ["airtable-issue-alerts@dot.ca.gov"],
    },
) as dag:
    # latest_only = LatestOnlyOperator(
    #     task_id="latest_only",
    #     depends_on_past=False,
    # )

    airtable_issues = BigQueryToAirtableIssuesOperator(
        task_id="bigquery_to_airtable_issues",
        retries=1,
        retry_delay=timedelta(seconds=10),
        dataset_name="mart_transit_database",
        table_name="fct_close_expired_issues",
    )

    update_airtable_issues = AirtableIssuesUpdateOperator(
        task_id="update_airtable_issues",
        retries=1,
        retry_delay=timedelta(seconds=10),
        airtable_conn_id="airtable_issue_management",
        air_base_id="appmBGOFTvsDv4jdJ",
        air_table_name="Transit Data Quality Issues",
        source_task_id="bigquery_to_airtable_issues",
    )

    send_airtable_issue_email = AirtableIssuesEmailOperator(
        task_id="send_airtable_issue_email",
        retries=1,
        retry_delay=timedelta(seconds=10),
        to_emails=dag.default_args["email"],
        subject="[Airflow] Airtable Issue Management",
        source_task_id="update_airtable_issues",
    )

    (
        # latest_only
        # >> airtable_issues
        airtable_issues
        >> update_airtable_issues
        >> send_airtable_issue_email
    )
