import os
from datetime import datetime

from cosmos import DbtTaskGroup, ProfileConfig, ProjectConfig, RenderConfig
from cosmos.constants import TestBehavior

from airflow import DAG
from airflow.operators.latest_only import LatestOnlyOperator

DBT_TARGET = os.environ.get("DBT_TARGET")

with DAG(
    dag_id="dbt_daily",
    tags=["dbt", "daily"],
    #  Sunday, Tuesday, Wednesday, Friday, Saturday at 7am PDT/8am PST (2pm UTC)
    schedule="0 14 * * 0,2,3,5,6",
    start_date=datetime(2025, 8, 19),
    catchup=False,
):
    latest_only = LatestOnlyOperator(task_id="latest_only", depends_on_past=False)

    dbt_daily = DbtTaskGroup(
        group_id="dbt_daily",
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
                "+path:models/mart/gtfs/fct_schedule_feed_downloads",
                "+path:models/mart/benefits/fct_benefits_events"
                "path:models/staging/audit/stg_audit__cloudaudit_googleapis_com_data_access+",
            ],
            test_behavior=TestBehavior.AFTER_ALL,
        ),
        operator_args={
            "install_deps": True,
        },
        default_args={"retries": 1},
    )

    latest_only >> dbt_daily
