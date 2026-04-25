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

    with TaskGroup("expiring_issues_close") as expiring_issues_close:
        get_expiring_issues_close_candidates = TDQBigQueryRowsOperator(
            task_id="get_expiring_issues_close_candidates",
            retries=1,
            retry_delay=timedelta(seconds=10),
            dataset_name="mart_transit_database",
            table_name="fct_close_expired_issues",
        )

        update_airtable_expiring_issues = AirtableIssuesUpdateOperator(
            task_id="update_airtable_expiring_issues",
            retries=1,
            retry_delay=timedelta(seconds=10),
            airtable_conn_id="airtable_issue_management",
            air_base_id="appmBGOFTvsDv4jdJ",
            air_table_name=dag.default_args["air_table_name"],
            rows=XComArg(get_expiring_issues_close_candidates),
        )

        get_expiring_issues_close_candidates >> update_airtable_expiring_issues

    with TaskGroup("expiring_issues_create") as expiring_issues_create:
        get_expiring_issues_create_candidates = TDQBigQueryRowsOperator(
            task_id="get_expiring_issues_create_candidates",
            retries=1,
            retry_delay=timedelta(seconds=10),
            dataset_name="mart_transit_database",
            table_name="fct_create_expiring_gtfs_issues",
        )

        create_airtable_expiring_issues = AirtableIssuesCreateOperator(
            task_id="create_airtable_expiring_issues",
            retries=1,
            retry_delay=timedelta(seconds=10),
            airtable_conn_id="airtable_issue_management",
            air_base_id="appmBGOFTvsDv4jdJ",
            air_table_name=dag.default_args["air_table_name"],
            rows=XComArg(get_expiring_issues_create_candidates),
        )

        get_expiring_issues_create_candidates >> create_airtable_expiring_issues

    with TaskGroup("rt_completeness_issues_close") as rt_completeness_issues_close:
        get_rt_completeness_close_candidates = TDQBigQueryRowsOperator(
            task_id="get_rt_completeness_close_candidates",
            retries=1,
            retry_delay=timedelta(seconds=10),
            dataset_name="mart_transit_database",
            table_name="fct_close_rt_completeness_issues",
        )

        update_airtable_rt_completeness_issues = AirtableIssuesUpdateOperator(
            task_id="update_airtable_rt_completeness_issues",
            retries=1,
            retry_delay=timedelta(seconds=10),
            airtable_conn_id="airtable_issue_management",
            air_base_id="appmBGOFTvsDv4jdJ",
            air_table_name=dag.default_args["air_table_name"],
            rows=XComArg(get_rt_completeness_close_candidates),
        )

        get_rt_completeness_close_candidates >> update_airtable_rt_completeness_issues

    # Future Task:
    # with TaskGroup("rt_completeness_issues_create") as rt_completeness_issues_create:
    #     get_rt_completeness_create_candidates = TDQBigQueryRowsOperator(
    #         task_id="get_rt_completeness_create_candidates",
    #         retries=1,
    #         retry_delay=timedelta(seconds=10),
    #         dataset_name="mart_transit_database",
    #         table_name="fct_create_rt_completeness_issues",  # example name
    #     )

    #     create_airtable_rt_completeness_issues = AirtableIssuesCreateOperator(
    #         task_id="create_airtable_rt_completeness_issues",
    #         retries=1,
    #         retry_delay=timedelta(seconds=10),
    #         airtable_conn_id="airtable_issue_management",
    #         air_base_id="appmBGOFTvsDv4jdJ",
    #         air_table_name=dag.default_args["air_table_name"],
    #         rows=XComArg(get_rt_completeness_create_candidates),
    #     )

    #     get_rt_completeness_create_candidates >> create_airtable_rt_completeness_issues

    send_airtable_issue_email = AirtableIssuesEmailOperator(
        task_id="send_airtable_issue_email",
        retries=1,
        retry_delay=timedelta(seconds=10),
        to_emails=dag.default_args["email"],
        subject="[Airflow] Airtable Issue Management",
        expiring_update_result=XComArg(update_airtable_expiring_issues),
        expiring_create_result=XComArg(create_airtable_expiring_issues),
        rt_update_result=XComArg(update_airtable_rt_completeness_issues),
        # rt_create_result=XComArg(create_airtable_rt_completeness_issues),
    )

    latest_only >> [
        expiring_issues_close,
        expiring_issues_create,
        rt_completeness_issues_close,
        # rt_completeness_issues_create,
    ]

    [
        expiring_issues_close,
        expiring_issues_create,
        rt_completeness_issues_close,
        # rt_completeness_issues_create,
    ] >> send_airtable_issue_email
