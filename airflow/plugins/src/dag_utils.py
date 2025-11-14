import os

import requests
from cosmos import ProfileConfig, ProjectConfig


def log_group_failure_to_slack(context):
    # pointed at #alerts-data-infra as of 2024-02-05
    CALITP_SLACK_URL = os.environ.get("CALITP_SLACK_URL")

    if not CALITP_SLACK_URL:
        print("Skipping email to slack channel. No CALITP_SLACK_URL in environment")
    else:
        try:
            task_instance = context.get("task_instance")
            dag_id = context.get("dag").dag_id
            task_id = task_instance.task_id
            log_url = task_instance.log_url
            execution_date = context.get("execution_date")

            message = f"""
            Task Failed: {dag_id}.{task_id}
            Execution Date: {execution_date}

            <{log_url}| Check Log >
            """
            requests.post(CALITP_SLACK_URL, json={"text": message})
            print(f"Slack notification sent: {message}")
        except Exception as e:
            # This is very broad but we want to try to log _any_ exception to slack
            print(f"Slack notification failed: {type(e)}")
            requests.post(
                CALITP_SLACK_URL, json={"text": f"failed to log {type(e)} to slack"}
            )


DBT_TARGET = os.environ.get("DBT_TARGET")

profile_config = ProfileConfig(
    target_name=DBT_TARGET,
    profile_name="calitp_warehouse",
    profiles_yml_filepath="/home/airflow/gcs/data/warehouse/profiles.yml",
)

project_config = ProjectConfig(
    project_name="calitp_warehouse",
    dbt_project_path="/home/airflow/gcs/data/warehouse",
    manifest_path="/home/airflow/gcs/data/warehouse/target/manifest.json",
    models_relative_path="models",
    seeds_relative_path="seeds/",
)

operator_args = {"install_deps": True}

default_args = {
    "on_failure_callback": log_group_failure_to_slack,
    "retries": 1,
}

# DAG: dbt_manual
dbt_manual_list = [
    "models/intermediate/gtfs/int_gtfs_rt__trip_updates_trip_stop_day_map_grouping.sql",
    "models/mart/gtfs/fct_stop_time_metrics.sql",
    "models/mart/gtfs/fct_stop_time_updates_sample.sql",
    "models/mart/gtfs/fct_trip_updates_stop_metrics.sql",
    "models/mart/gtfs/fct_trip_updates_trip_metrics.sql",
]

# DAG: dbt_daily
dbt_daily_gtfs_schedule_list = ["+fct_schedule_feed_downloads"]

# DAG: dbt_daily and dbt_all
dbt_audit_list = [
    "models/staging/audit",
    "models/mart/audit",
]

dbt_benefits_list = [
    "models/staging/amplitude",
    "models/mart/benefits",
]

dbt_kuba_list = [
    "models/staging/kuba",
    "models/intermediate/kuba",
    "models/mart/kuba",
]

dbt_payments_list = [
    "models/staging/payments",
    "models/intermediate/payments",
    "models/mart/payments",
]

# DAG: dbt_all
dbt_gtfs_list = [
    "models/staging/gtfs",
    "models/staging/rt",
    "models/intermediate/gtfs",
    "models/mart/gtfs",
]

dbt_gtfs_quality_list = [
    "models/staging/gtfs_quality",
    "models/intermediate/gtfs_quality",
    "models/mart/gtfs_quality",
]

dbt_gtfs_rollup_list = [
    "models/mart/gtfs_rollup",
]

dbt_gtfs_schedule_latest_list = [
    "models/mart/gtfs_schedule_latest",
]

dbt_ntd_list = [
    "models/staging/ntd_annual_reporting",
    "models/staging/ntd_assets",
    "models/staging/ntd_funding_and_expenses",
    "models/staging/ntd_ridership",
    "models/staging/ntd_safety_and_security",
    "models/intermediate/ntd_annual_reporting",
    "models/intermediate/ntd_assets",
    "models/intermediate/ntd_funding_and_expenses",
    "models/mart/ntd",
    "models/mart/ntd_annual_reporting",
    "models/mart/ntd_assets",
    "models/mart/ntd_funding_and_expenses",
    "models/mart/ntd_ridership",
    "models/mart/ntd_safety_and_security",
]

dbt_ntd_validation_list = [
    "models/staging/ntd_validation",
    "models/intermediate/ntd_validation",
    "models/mart/ntd_validation",
]

dbt_state_geoportal_list = [
    "models/staging/state_geoportal",
]

dbt_transit_database_list = [
    "models/staging/transit_database",
    "models/intermediate/transit_database",
    "models/mart/transit_database",
    "models/mart/transit_database_latest",
]
