import os
from datetime import datetime

from cosmos import DbtTaskGroup, ProfileConfig, ProjectConfig, RenderConfig
from cosmos.constants import TestBehavior
from src.dbt_dag_lists import (
    audit_list,
    benefits_list,
    gtfs_list,
    gtfs_quality_list,
    gtfs_rollup_list,
    gtfs_schedule_latest_list,
    kuba_list,
    manual_list,
    ntd_list,
    ntd_validation_list,
    payments_list,
    state_geoportal_list,
    transit_database_list,
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
    dag_id="dbt_all",
    tags=["dbt", "all"],
    # Monday, Thursday at 7am PDT/8am PST (2pm UTC)
    schedule="0 14 * * 1,4",
    start_date=datetime(2025, 7, 6),
    catchup=False,
):
    latest_only = LatestOnlyOperator(task_id="latest_only", depends_on_past=False)

    dbt_audit = DbtTaskGroup(
        group_id="audit",
        project_config=project_config,
        profile_config=profile_config,
        render_config=RenderConfig(
            select=audit_list,
            exclude=manual_list,
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
            exclude=manual_list,
            test_behavior=TestBehavior.AFTER_ALL,
        ),
        operator_args={
            "install_deps": True,
        },
        default_args={"retries": 1},
    )

    dbt_gtfs = DbtTaskGroup(
        group_id="gtfs",
        project_config=project_config,
        profile_config=profile_config,
        render_config=RenderConfig(
            select=gtfs_list,
            exclude=manual_list,
            test_behavior=None,
        ),
        operator_args={
            "install_deps": True,
        },
        default_args={"retries": 1},
    )

    dbt_gtfs_quality = DbtTaskGroup(
        group_id="gtfs_quality",
        project_config=project_config,
        profile_config=profile_config,
        render_config=RenderConfig(
            select=gtfs_quality_list,
            exclude=manual_list,
            test_behavior=None,
        ),
        operator_args={
            "install_deps": True,
        },
        default_args={"retries": 1},
    )

    dbt_gtfs_rollup = DbtTaskGroup(
        group_id="gtfs_rollup",
        project_config=project_config,
        profile_config=profile_config,
        render_config=RenderConfig(
            select=gtfs_rollup_list,
            exclude=manual_list,
            test_behavior=None,
        ),
        operator_args={
            "install_deps": True,
        },
        default_args={"retries": 1},
    )

    dbt_gtfs_schedule_latest = DbtTaskGroup(
        group_id="gtfs_schedule_latest",
        project_config=project_config,
        profile_config=profile_config,
        render_config=RenderConfig(
            select=gtfs_schedule_latest_list,
            exclude=manual_list,
            test_behavior=None,
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
            exclude=manual_list,
            test_behavior=TestBehavior.AFTER_ALL,
        ),
        operator_args={
            "install_deps": True,
        },
        default_args={"retries": 1},
    )

    dbt_ntd = DbtTaskGroup(
        group_id="ntd",
        project_config=project_config,
        profile_config=profile_config,
        render_config=RenderConfig(
            select=ntd_list,
            exclude=manual_list,
            test_behavior=None,
        ),
        operator_args={
            "install_deps": True,
        },
        default_args={"retries": 1},
    )

    dbt_ntd_validation = DbtTaskGroup(
        group_id="ntd_validation",
        project_config=project_config,
        profile_config=profile_config,
        render_config=RenderConfig(
            select=ntd_validation_list,
            exclude=manual_list,
            test_behavior=None,
        ),
        operator_args={
            "install_deps": True,
        },
        default_args={"retries": 1},
    )

    dbt_payments = DbtTaskGroup(
        group_id="payments",
        project_config=project_config,
        profile_config=profile_config,
        render_config=RenderConfig(
            select=payments_list,
            exclude=manual_list,
            test_behavior=None,
        ),
        operator_args={
            "install_deps": True,
        },
        default_args={"retries": 1},
    )

    dbt_state_geoportal = DbtTaskGroup(
        group_id="state_geoportal",
        project_config=project_config,
        profile_config=profile_config,
        render_config=RenderConfig(
            select=state_geoportal_list,
            exclude=manual_list,
            test_behavior=TestBehavior.AFTER_ALL,
        ),
        operator_args={
            "install_deps": True,
        },
        default_args={"retries": 1},
    )

    dbt_transit_database = DbtTaskGroup(
        group_id="transit_database",
        project_config=project_config,
        profile_config=profile_config,
        render_config=RenderConfig(
            select=transit_database_list,
            exclude=manual_list,
            test_behavior=None,
        ),
        operator_args={
            "install_deps": True,
        },
        default_args={"retries": 1},
    )

    latest_only >> dbt_audit
    latest_only >> dbt_benefits
    latest_only >> dbt_gtfs
    dbt_gtfs >> dbt_gtfs_quality
    dbt_gtfs >> dbt_gtfs_rollup
    dbt_gtfs >> dbt_gtfs_schedule_latest
    latest_only >> dbt_kuba
    latest_only >> dbt_ntd
    latest_only >> dbt_ntd_validation
    latest_only >> dbt_payments
    latest_only >> dbt_state_geoportal
    latest_only >> dbt_transit_database
