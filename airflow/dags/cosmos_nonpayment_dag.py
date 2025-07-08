import os
from datetime import datetime

from cosmos import DbtDag, ProfileConfig, ProjectConfig, RenderConfig
from cosmos.constants import TestBehavior

DBT_TARGET = os.environ.get("DBT_TARGET")

cosmos_nonpayment = DbtDag(
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
        exclude=[
            "+path:models/staging/payments+",
            "+path:models/intermediate/payments+",
            "+path:models/mart/payments+",
        ],
        test_behavior=TestBehavior.NONE,
    ),
    operator_args={"install_deps": True},
    # normal dag parameters
    schedule_interval="@weekly",
    start_date=datetime(2025, 7, 1),
    catchup=False,
    dag_id="cosmos_nonpayment",
    tags=["dbt"],
    default_args={"retries": 0},
)
