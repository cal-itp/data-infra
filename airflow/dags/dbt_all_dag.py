import os
from datetime import datetime

from cosmos import DbtTaskGroup, ProfileConfig, ProjectConfig, RenderConfig
from src.dag_utils import log_group_failure_to_slack

from airflow import DAG
from airflow.operators.latest_only import LatestOnlyOperator

DBT_TARGET = os.environ.get("DBT_TARGET")

with DAG(
    dag_id="dbt_all",
    tags=["dbt", "all"],
    # Monday, Thursday at 4am PDT/5am PST (12pm UTC)
    schedule="0 12 * * 1,4",
    start_date=datetime(2025, 7, 6),
    catchup=False,
    default_args={
        "email": os.getenv("CALITP_NOTIFY_EMAIL"),
        "email_on_failure": True,
        "email_on_retry": False,
    },
):
    latest_only = LatestOnlyOperator(task_id="latest_only", depends_on_past=False)

    dbt_all = DbtTaskGroup(
        group_id="dbt_all",
        project_config=ProjectConfig(
            dbt_project_path="/home/airflow/gcs/data/warehouse",
            manifest_path="/home/airflow/gcs/data/warehouse/target/manifest.json",
            project_name="calitp_warehouse",
            seeds_relative_path="seeds/",
        ),
        profile_config=ProfileConfig(
            target_name=DBT_TARGET,
            profile_name="calitp_warehouse",
            profiles_yml_filepath="/home/airflow/gcs/data/warehouse/profiles.yml",
        ),
        render_config=RenderConfig(
            exclude=[
                "models/intermediate/gtfs/int_gtfs_rt__trip_updates_trip_stop_day_map_grouping.sql",
                "models/mart/gtfs/fct_stop_time_metrics.sql",
                "models/mart/gtfs/fct_trip_updates_stop_metrics.sql",
                "models/mart/gtfs/fct_trip_updates_trip_metrics.sql",
            ],
            test_behavior=None,
        ),
        operator_args={
            "install_deps": True,
        },
        default_args={
            "on_failure_callback": log_group_failure_to_slack,
            "retries": 1,
        },
    )

    latest_only >> dbt_all
