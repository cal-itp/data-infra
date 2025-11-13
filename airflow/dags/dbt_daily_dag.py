import os
from datetime import datetime

from cosmos import DbtTaskGroup, ProfileConfig, ProjectConfig, RenderConfig
from cosmos.constants import TestBehavior
from src.dbt_dag_lists import (
    audit_list,
    benefits_list,
    daily_gtfs_schedule_list,
    kuba_list,
)

from airflow import DAG
from airflow.operators.latest_only import LatestOnlyOperator

DBT_TARGET = os.environ.get("DBT_TARGET")

project_config = ProjectConfig(
    project_name="calitp_warehouse",
    dbt_project_path="/home/airflow/gcs/data/warehouse",
    manifest_path="/home/airflow/gcs/data/warehouse/target/manifest.json",
    models_relative_path="models",
    seeds_relative_path="seeds/",
)

profile_config = ProfileConfig(
    target_name=DBT_TARGET,
    profile_name="calitp_warehouse",
    profiles_yml_filepath="/home/airflow/gcs/data/warehouse/profiles.yml",
)

with DAG(
    dag_id="dbt_daily",
    tags=["dbt", "daily"],
    #  Sunday, Tuesday, Wednesday, Friday, Saturday at 7am PDT/8am PST (2pm UTC)
    schedule="0 14 * * 0,2,3,5,6",
    start_date=datetime(2025, 8, 19),
    catchup=False,
):
    latest_only = LatestOnlyOperator(task_id="latest_only", depends_on_past=False)

    dbt_audit = DbtTaskGroup(
        group_id="audit",
        project_config=project_config,
        profile_config=profile_config,
        render_config=RenderConfig(
            select=audit_list,
            test_behavior=TestBehavior.AFTER_ALL,
        ),
        operator_args={
            "install_deps": True,
        },
        default_args={"retries": 1},
    )

    dbt_benefits = DbtTaskGroup(
        group_id="benefits",
        project_config=project_config,
        profile_config=profile_config,
        render_config=RenderConfig(
            select=benefits_list,
            test_behavior=TestBehavior.AFTER_ALL,
        ),
        operator_args={
            "install_deps": True,
        },
        default_args={"retries": 1},
    )

    dbt_gtfs_schedule = DbtTaskGroup(
        group_id="gtfs_schedule",
        project_config=project_config,
        profile_config=profile_config,
        render_config=RenderConfig(
            select=daily_gtfs_schedule_list,
            test_behavior=TestBehavior.AFTER_ALL,
        ),
        operator_args={
            "install_deps": True,
        },
        default_args={"retries": 1},
    )

    dbt_kuba = DbtTaskGroup(
        group_id="kuba",
        project_config=project_config,
        profile_config=profile_config,
        render_config=RenderConfig(
            select=kuba_list,
            test_behavior=TestBehavior.AFTER_ALL,
        ),
        operator_args={
            "install_deps": True,
        },
        default_args={"retries": 1},
    )

    latest_only >> dbt_audit
    latest_only >> dbt_benefits
    latest_only >> dbt_gtfs_schedule
    latest_only >> dbt_kuba
