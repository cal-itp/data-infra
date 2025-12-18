import os
from datetime import datetime

from cosmos import DbtTaskGroup, ProfileConfig, ProjectConfig, RenderConfig
from cosmos.constants import TestBehavior
from src.dag_utils import log_group_failure_to_slack

from airflow import DAG
from airflow.operators.latest_only import LatestOnlyOperator

DBT_TARGET = os.environ.get("DBT_TARGET")

with DAG(
    dag_id="dbt_manual",
    tags=["dbt", "manual", "ad-hoc"],
    schedule=None,
    start_date=datetime(2025, 7, 21),
    catchup=False,
):
    latest_only = LatestOnlyOperator(task_id="latest_only", depends_on_past=False)

    dbt_manual = DbtTaskGroup(
        group_id="dbt_manual",
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
            select=[
                "models/intermediate/gtfs/int_gtfs_rt__trip_updates_trip_stop_day_map_grouping.sql",
                "models/mart/gtfs/fct_stop_time_metrics.sql",
                "models/mart/gtfs/fct_stop_time_updates_sample.sql",
                "models/mart/gtfs/fct_trip_updates_stop_metrics.sql",
                "models/mart/gtfs/fct_trip_updates_trip_metrics.sql",
            ],
            test_behavior=TestBehavior.AFTER_ALL,
        ),
        operator_args={
            "install_deps": True,
        },
        default_args={
            "on_failure_callback": log_group_failure_to_slack,
            "retries": 0,
        },
    )

    latest_only >> dbt_manual
