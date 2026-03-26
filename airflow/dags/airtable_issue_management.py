import os
from datetime import datetime, timedelta

import pendulum
from operators.airtable_issues_email_operator import AirtableIssuesEmailOperator
from operators.airtable_issues_update_operator import AirtableIssuesUpdateOperator
from operators.bigquery_to_airtable_issues_operator import (
    BigQueryToAirtableIssuesOperator,
)

from airflow import DAG
from airflow.models.xcom_arg import XComArg
from airflow.operators.latest_only import LatestOnlyOperator

local_tz = pendulum.timezone("America/Los_Angeles")

with DAG(
    dag_id="airtable_issue_management",
    tags=["airtable", "tdq", "automation"],
    # Every Friday at 6am PT (1pm UTC during PDT / 2pm UTC during PST)
    schedule="0 6 * * 5",
    start_date=datetime(2026, 3, 20, tzinfo=local_tz),
    catchup=False,
    default_args={
        "email": [os.getenv("AIRTABLE_ISSUE_MANAGEMENT_EMAIL")],
        "air_table_name": os.getenv("TRANSIT_DATA_QUALITY_ISSUES"),
    },
) as dag:
    latest_only = LatestOnlyOperator(
        task_id="latest_only",
        depends_on_past=False,
    )

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
        air_table_name=dag.default_args["air_table_name"],
        rows=XComArg(airtable_issues),
    )

    send_airtable_issue_email = AirtableIssuesEmailOperator(
        task_id="send_airtable_issue_email",
        retries=1,
        retry_delay=timedelta(seconds=10),
        to_emails=dag.default_args["email"],
        subject="[Airflow] Airtable Issue Management",
        update_result=XComArg(update_airtable_issues),
    )

    (
        latest_only
        >> airtable_issues
        >> update_airtable_issues
        >> send_airtable_issue_email
    )
