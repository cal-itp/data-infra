import os
from datetime import datetime

from cosmos import DbtTaskGroup, ProfileConfig, ProjectConfig, RenderConfig

from airflow import DAG
from airflow.operators.latest_only import LatestOnlyOperator

DBT_TARGET = os.environ.get("DBT_TARGET")

with DAG(
    dag_id="dbt_payments",
    tags=["dbt", "payments"],
    # Sunday, Tuesday, Wednesday, Friday, Saturday at 7am PDT/8am PST (2pm UTC)
    schedule="0 14 * * 0,2,3,5,6",
    start_date=datetime(2025, 7, 6),
    catchup=False,
):
    latest_only = LatestOnlyOperator(task_id="latest_only", depends_on_past=False)

    dbt_payments = DbtTaskGroup(
        group_id="dbt_payments",
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
                "+path:models/staging/payments+",
                "+path:models/intermediate/payments+",
                "+path:models/mart/payments+",
            ],
            test_behavior=None,
        ),
        operator_args={
            "install_deps": True,
        },
        default_args={"retries": 1},
    )

    latest_only >> dbt_payments
