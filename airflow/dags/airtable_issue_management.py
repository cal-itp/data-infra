import os
from datetime import datetime, timedelta

import pendulum
from operators.airtable_issues_create_operator import AirtableIssuesCreateOperator
from operators.airtable_issues_email_operator import AirtableIssuesEmailOperator
from operators.airtable_issues_update_operator import AirtableIssuesUpdateOperator
from operators.tdq_bigquery_rows_operator import TDQBigQueryRowsOperator

from airflow import DAG
from airflow.models.xcom_arg import XComArg
from airflow.operators.latest_only import LatestOnlyOperator
from airflow.utils.task_group import TaskGroup

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

    with TaskGroup("close_expired_issues") as close_expired_issues:
        close_expired_issue_candidates = TDQBigQueryRowsOperator(
            task_id="bq_close_expired_issues_candidates",
            retries=1,
            retry_delay=timedelta(seconds=10),
            dataset_name="mart_transit_database",
            table_name="fct_close_expired_issues",
            columns=[
                "issue_number",
                "issue_source_record_id",
                "outreach_status",
                "gtfs_dataset_name",
                "new_end_date",
            ],
        )

        update_airtable_issues = AirtableIssuesUpdateOperator(
            task_id="update_airtable_issues",
            retries=1,
            retry_delay=timedelta(seconds=10),
            airtable_conn_id="airtable_issue_management",
            air_base_id="appmBGOFTvsDv4jdJ",
            air_table_name=dag.default_args["air_table_name"],
            rows=XComArg(close_expired_issue_candidates),
        )

        close_expired_issue_candidates >> update_airtable_issues

    with TaskGroup("create_expiring_issues") as create_expiring_issues:
        create_expiring_issue_candidates = TDQBigQueryRowsOperator(
            task_id="bq_create_expiring_issues_candidates",
            retries=1,
            retry_delay=timedelta(seconds=10),
            dataset_name="mart_transit_database",
            table_name="fct_create_expiring_gtfs_issues",
            columns=[
                "gtfs_dataset_name",
                "gtfs_dataset_record_id",
                "service_name",
                "service_record_id",
                "max_end_date",
                "expiration_status",
            ],
        )

        create_airtable_issues = AirtableIssuesCreateOperator(
            task_id="create_airtable_issues",
            retries=1,
            retry_delay=timedelta(seconds=10),
            airtable_conn_id="airtable_issue_management",
            air_base_id="appmBGOFTvsDv4jdJ",
            air_table_name=dag.default_args["air_table_name"],
            rows=XComArg(create_expiring_issue_candidates),
        )

        create_expiring_issue_candidates >> create_airtable_issues

    send_airtable_issue_email = AirtableIssuesEmailOperator(
        task_id="send_airtable_issue_email",
        retries=1,
        retry_delay=timedelta(seconds=10),
        to_emails=dag.default_args["email"],
        subject="[Airflow] Airtable Issue Management",
        update_result=XComArg(update_airtable_issues),
        create_result=XComArg(create_airtable_issues),
    )

    latest_only >> [close_expired_issues, create_expiring_issues]
    [close_expired_issues, create_expiring_issues] >> send_airtable_issue_email
