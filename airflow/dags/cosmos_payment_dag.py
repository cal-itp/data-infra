from datetime import datetime

from cosmos import DbtDag, ProfileConfig, ProjectConfig, RenderConfig

cosmos_payment = DbtDag(
    # dbt/cosmos-specific parameters
    project_config=ProjectConfig(
        dbt_project_path="/home/airflow/gcs/data/warehouse",
        manifest_path="/home/airflow/gcs/data/warehouse/target/manifest.json",
    ),
    profile_config=ProfileConfig(
        target_name="staging",
        profile_name="calitp_warehouse",
        profiles_yml_filepath="/home/airflow/gcs/data/warehouse/profiles.yml",
    ),
    render_config=RenderConfig(
        select=[
            "+path:models/staging/payments+",
            "+path:models/intermediate/payments+",
            "+path:models/mart/payments+",
        ],
    ),
    # normal dag parameters
    schedule_interval="@daily",
    start_date=datetime(2023, 1, 1),
    catchup=False,
    dag_id="cosmos_payment",
    tags=["dbt", "payments"],
)
