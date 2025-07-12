import os
from datetime import datetime

from cosmos import DbtDag, ProfileConfig, ProjectConfig, RenderConfig
from cosmos.constants import TestBehavior

DBT_TARGET = os.environ.get("DBT_TARGET")

dbt_all = DbtDag(
    # dbt/cosmos-specific parameters
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
        test_behavior=TestBehavior.AFTER_ALL,
    ),
    operator_args={
        "install_deps": True,
    },
    # Monday, Thursday at 7am PDT/8am PST (2pm UTC)
    schedule="0 14 * * 1,4",
    start_date=datetime(2025, 7, 6),
    catchup=False,
    latest_only=True,
    dag_id="dbt_all",
    tags=["dbt", "all"],
    default_args={"retries": 0},
)
