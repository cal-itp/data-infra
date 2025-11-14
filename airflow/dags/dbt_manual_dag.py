from datetime import datetime

from cosmos import DbtTaskGroup, RenderConfig
from cosmos.constants import TestBehavior
from src.dag_utils import (
    dbt_manual_list,
    default_args,
    operator_args,
    profile_config,
    project_config,
)

from airflow import DAG
from airflow.operators.latest_only import LatestOnlyOperator

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
        project_config=project_config,
        profile_config=profile_config,
        operator_args=operator_args,
        default_args=default_args,
        render_config=RenderConfig(
            select=dbt_manual_list,
            test_behavior=TestBehavior.AFTER_ALL,
        ),
    )

    latest_only >> dbt_manual
