import os
from datetime import datetime
from pathlib import Path

from cosmos import DbtTaskGroup, ProfileConfig, ProjectConfig, RenderConfig
from src.dbt_dag_lists import manual_list

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
# total 605 models

paths = [
    "/home/airflow/gcs/data/warehouse/models/staging",
    "/home/airflow/gcs/data/warehouse/models/intermediate",
    "/home/airflow/gcs/data/warehouse/models/mart",
]
model_groups = set()
for path in paths:
    for sub_path in Path(path).glob("*"):
        if sub_path.is_dir():
            model_groups.add(os.path.basename(sub_path))

with DAG(
    dag_id="dbt_all",
    tags=["dbt", "all"],
    # Monday, Thursday at 7am PDT/8am PST (2pm UTC)
    schedule="0 14 * * 1,4",
    start_date=datetime(2025, 7, 6),
    catchup=False,
):
    latest_only = LatestOnlyOperator(task_id="latest_only", depends_on_past=False)
    dbt_groups = []

    for models_group in set(model_groups):
        dbt_groups.append(
            DbtTaskGroup(
                group_id=models_group,
                project_config=project_config,
                profile_config=profile_config,
                render_config=RenderConfig(
                    select=[
                        f"models/staging/{models_group}",
                        f"models/intermediate/{models_group}",
                        f"models/mart/{models_group}",
                    ],
                    exclude=manual_list,
                    test_behavior=None,
                ),
                operator_args={
                    "install_deps": True,
                },
                default_args={"retries": 1},
            )
        )

    for i in range(len(dbt_groups)):
        latest_only >> dbt_groups[i]
