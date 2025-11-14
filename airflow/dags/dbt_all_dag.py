from datetime import datetime

from cosmos import DbtTaskGroup, RenderConfig
from cosmos.constants import TestBehavior
from src.dag_utils import (
    dbt_audit_list,
    dbt_benefits_list,
    dbt_gtfs_list,
    dbt_gtfs_quality_list,
    dbt_gtfs_rollup_list,
    dbt_gtfs_schedule_latest_list,
    dbt_kuba_list,
    dbt_manual_list,
    dbt_ntd_list,
    dbt_ntd_validation_list,
    dbt_payments_list,
    dbt_state_geoportal_list,
    dbt_transit_database_list,
    default_args,
    operator_args,
    profile_config,
    project_config,
)

from airflow import DAG
from airflow.operators.latest_only import LatestOnlyOperator

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
        operator_args=operator_args,
        default_args=default_args,
        render_config=RenderConfig(
            select=dbt_audit_list,
            exclude=dbt_manual_list,
            test_behavior=TestBehavior.AFTER_ALL,
        ),
    )

    dbt_benefits = DbtTaskGroup(
        group_id="benefits",
        project_config=project_config,
        profile_config=profile_config,
        operator_args=operator_args,
        default_args=default_args,
        render_config=RenderConfig(
            select=dbt_benefits_list,
            exclude=dbt_manual_list,
            test_behavior=TestBehavior.AFTER_ALL,
        ),
    )

    dbt_gtfs = DbtTaskGroup(
        group_id="gtfs",
        project_config=project_config,
        profile_config=profile_config,
        operator_args=operator_args,
        default_args=default_args,
        render_config=RenderConfig(
            select=dbt_gtfs_list,
            exclude=dbt_manual_list,
            test_behavior=None,
        ),
    )

    dbt_gtfs_quality = DbtTaskGroup(
        group_id="gtfs_quality",
        project_config=project_config,
        profile_config=profile_config,
        operator_args=operator_args,
        default_args=default_args,
        render_config=RenderConfig(
            select=dbt_gtfs_quality_list,
            exclude=dbt_manual_list,
            test_behavior=None,
        ),
    )

    dbt_gtfs_rollup = DbtTaskGroup(
        group_id="gtfs_rollup",
        project_config=project_config,
        profile_config=profile_config,
        operator_args=operator_args,
        default_args=default_args,
        render_config=RenderConfig(
            select=dbt_gtfs_rollup_list,
            exclude=dbt_manual_list,
            test_behavior=None,
        ),
    )

    dbt_gtfs_schedule_latest = DbtTaskGroup(
        group_id="gtfs_schedule_latest",
        project_config=project_config,
        profile_config=profile_config,
        operator_args=operator_args,
        default_args=default_args,
        render_config=RenderConfig(
            select=dbt_gtfs_schedule_latest_list,
            exclude=dbt_manual_list,
            test_behavior=None,
        ),
    )

    dbt_kuba = DbtTaskGroup(
        group_id="kuba",
        project_config=project_config,
        profile_config=profile_config,
        operator_args=operator_args,
        default_args=default_args,
        render_config=RenderConfig(
            select=dbt_kuba_list,
            exclude=dbt_manual_list,
            test_behavior=TestBehavior.AFTER_ALL,
        ),
    )

    dbt_ntd = DbtTaskGroup(
        group_id="ntd",
        project_config=project_config,
        profile_config=profile_config,
        operator_args=operator_args,
        default_args=default_args,
        render_config=RenderConfig(
            select=dbt_ntd_list,
            exclude=dbt_manual_list,
            test_behavior=None,
        ),
    )

    dbt_ntd_validation = DbtTaskGroup(
        group_id="ntd_validation",
        project_config=project_config,
        profile_config=profile_config,
        operator_args=operator_args,
        default_args=default_args,
        render_config=RenderConfig(
            select=dbt_ntd_validation_list,
            exclude=dbt_manual_list,
            test_behavior=None,
        ),
    )

    dbt_payments = DbtTaskGroup(
        group_id="payments",
        project_config=project_config,
        profile_config=profile_config,
        operator_args=operator_args,
        default_args=default_args,
        render_config=RenderConfig(
            select=dbt_payments_list,
            exclude=dbt_manual_list,
            test_behavior=None,
        ),
    )

    dbt_state_geoportal = DbtTaskGroup(
        group_id="state_geoportal",
        project_config=project_config,
        profile_config=profile_config,
        operator_args=operator_args,
        default_args=default_args,
        render_config=RenderConfig(
            select=dbt_state_geoportal_list,
            exclude=dbt_manual_list,
            test_behavior=TestBehavior.AFTER_ALL,
        ),
    )

    dbt_transit_database = DbtTaskGroup(
        group_id="transit_database",
        project_config=project_config,
        profile_config=profile_config,
        operator_args=operator_args,
        default_args=default_args,
        render_config=RenderConfig(
            select=dbt_transit_database_list,
            exclude=dbt_manual_list,
            test_behavior=None,
        ),
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
