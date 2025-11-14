from datetime import datetime

from cosmos import DbtTaskGroup, RenderConfig
from cosmos.constants import TestBehavior
from src.dag_utils import (
    dbt_audit_list,
    dbt_benefits_list,
    dbt_daily_gtfs_schedule_list,
    dbt_kuba_list,
    dbt_payments_list,
    default_args,
    operator_args,
    profile_config,
    project_config,
)

from airflow import DAG
from airflow.operators.latest_only import LatestOnlyOperator

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
        operator_args=operator_args,
        default_args=default_args,
        render_config=RenderConfig(
            select=[
                "source:external_kuba+",
                "models/staging/audit",
                "models/mart/audit",
            ],
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
            test_behavior=TestBehavior.AFTER_ALL,
        ),
    )

    dbt_gtfs_schedule = DbtTaskGroup(
        group_id="gtfs_schedule",
        project_config=project_config,
        profile_config=profile_config,
        operator_args=operator_args,
        default_args=default_args,
        render_config=RenderConfig(
            select=dbt_daily_gtfs_schedule_list,
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
            test_behavior=TestBehavior.AFTER_ALL,
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
            test_behavior=None,
        ),
    )

    latest_only >> dbt_audit
    latest_only >> dbt_benefits
    latest_only >> dbt_gtfs_schedule
    latest_only >> dbt_kuba
    latest_only >> dbt_payments
