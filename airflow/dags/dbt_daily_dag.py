import os
from datetime import datetime

from cosmos import DbtTaskGroup, ProfileConfig, ProjectConfig, RenderConfig
from src.dag_utils import log_group_failure_to_slack

from airflow import DAG
from airflow.operators.latest_only import LatestOnlyOperator

DBT_TARGET = os.environ.get("DBT_TARGET")

project_config = ProjectConfig(
    dbt_project_path="/home/airflow/gcs/data/warehouse",
    manifest_path="/home/airflow/gcs/data/warehouse/target/manifest.json",
    project_name="calitp_warehouse",
    seeds_relative_path="seeds/",
)

profile_config = ProfileConfig(
    target_name=DBT_TARGET,
    profile_name="calitp_warehouse",
    profiles_yml_filepath="/home/airflow/gcs/data/warehouse/profiles.yml",
)

default_args = {
    "on_failure_callback": log_group_failure_to_slack,
    "retries": 1,
}

with DAG(
    dag_id="dbt_daily",
    tags=["dbt", "daily"],
    #  Sunday, Tuesday, Wednesday, Friday, Saturday at 6am PDT/7am PST (2pm UTC)
    schedule="0 14 * * 0,2,3,5,6",
    start_date=datetime(2025, 8, 19),
    catchup=False,
    default_args={
        "email": os.getenv("CALITP_NOTIFY_EMAIL"),
        "email_on_failure": True,
        "email_on_retry": False,
    },
):
    latest_only = LatestOnlyOperator(task_id="latest_only", depends_on_past=False)

    dbt_audit = DbtTaskGroup(
        group_id="dbt_audit",
        project_config=project_config,
        profile_config=profile_config,
        render_config=RenderConfig(
            select=[
                "stg_audit__cloudaudit_googleapis_com_data_access+",
            ],
            test_behavior=None,
        ),
        operator_args={
            "install_deps": True,
        },
        default_args=default_args,
    )

    dbt_benefits = DbtTaskGroup(
        group_id="dbt_benefits",
        project_config=project_config,
        profile_config=profile_config,
        render_config=RenderConfig(
            select=[
                "+fct_benefits_events",
            ],
            test_behavior=None,
        ),
        operator_args={
            "install_deps": True,
        },
        default_args=default_args,
    )

    dbt_gtfs = DbtTaskGroup(
        group_id="dbt_gtfs",
        project_config=project_config,
        profile_config=profile_config,
        render_config=RenderConfig(
            select=[
                "models/mart/gtfs_audit",
                "+fct_schedule_feed_downloads",
                "+fct_schedule_feed_files",
            ],
            test_behavior=None,
        ),
        operator_args={
            "install_deps": True,
        },
        default_args=default_args,
    )

    dbt_kuba = DbtTaskGroup(
        group_id="dbt_kuba",
        project_config=project_config,
        profile_config=profile_config,
        render_config=RenderConfig(
            select=[
                "models/staging/kuba",
                "models/mart/kuba",
            ],
            test_behavior=None,
        ),
        operator_args={
            "install_deps": True,
        },
        default_args=default_args,
    )

    dbt_payments = DbtTaskGroup(
        group_id="dbt_payments",
        project_config=project_config,
        profile_config=profile_config,
        render_config=RenderConfig(
            select=[
                "models/staging/payments",
                "models/intermediate/payments",
                "models/mart/payments",
            ],
            test_behavior=None,
        ),
        operator_args={
            "install_deps": True,
        },
        default_args=default_args,
    )

    latest_only >> [dbt_audit, dbt_benefits, dbt_kuba]
    latest_only >> dbt_gtfs >> dbt_payments
