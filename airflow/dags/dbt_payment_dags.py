from datetime import datetime
from cosmos import DbtDag, ProfileConfig, ProjectConfig, RenderConfig


dbt_payments = DbtDag(
    # dbt/cosmos-specific parameters
    project_config=ProjectConfig(
        dbt_project_path="/home/airflow/gcs/data/warehouse"
    ),
    profile_config=ProfileConfig(
        target_name="staging",
        profile_name="calitp_warehouse",
        profiles_yml_filepath="/home/airflow/gcs/data/warehouse/profiles.yml",
    ),
    render_config=RenderConfig(
        select=[
            "+path:models/intermediate/payments+",
            "+path:models/mart/payments+",
            "+path:models/staging/payments+",
        ],
    ),
    # normal dag parameters
    schedule_interval="@daily",
    start_date=datetime(2025, 1, 1),
    catchup=False,
    dag_id="dbt_payments",
    tags=["dbt", "payments"],
)

dbt_ntd = DbtDag(
    # dbt/cosmos-specific parameters
    project_config=ProjectConfig(
        dbt_project_path="/home/airflow/gcs/data/warehouse"
    ),
    profile_config=ProfileConfig(
        target_name="staging",
        profile_name="calitp_warehouse",
        profiles_yml_filepath="/home/airflow/gcs/data/warehouse/profiles.yml",
    ),
    render_config=RenderConfig(
        exclude=[
            "path:models/intermediate/ntd+",
            "path:models/intermediate/ntd_funding_and_expenses+",
            "path:models/intermediate/ntd_validation+",
            "path:models/mart/ntd+",
            "path:models/mart/ntd_annual_reporting+",
            "path:models/mart/ntd_funding_and_expenses+",
            "path:models/mart/ntd_ridership+",
            "path:models/mart/ntd_safety_and_security+",
            "path:models/mart/ntd_validation+",
            "path:models/staging/ntd_annual_reporting+",
            "path:models/staging/ntd_funding_and_expenses+",
            "path:models/staging/ntd_ridership+",
            "path:models/staging/ntd_safety_and_security+",
            "path:models/staging/ntd_validation+",
        ],
    ),
    # normal dag parameters
    schedule_interval="@monthly",
    start_date=datetime(2025, 1, 1),
    catchup=False,
    dag_id="dbt_ntd",
    tags=["dbt", "ntd"],
)

dbt_gtfs = DbtDag(
    # dbt/cosmos-specific parameters
    project_config=ProjectConfig(
        dbt_project_path="/home/airflow/gcs/data/warehouse"
    ),
    profile_config=ProfileConfig(
        target_name="staging",
        profile_name="calitp_warehouse",
        profiles_yml_filepath="/home/airflow/gcs/data/warehouse/profiles.yml",
    ),
    render_config=RenderConfig(
        exclude=[
            "path:models/intermediate/gtfs+",
            "path:models/intermediate/gtfs_quality+",
            "path:models/mart/gtfs+",
            "path:models/mart/gtfs_quality+",
            "path:models/mart/gtfs_schedule_latest+",
            "path:models/staging/gtfs+",
            "path:models/staging/gtfs_quality+",
            "path:models/staging/rt+",
        ],
    ),
    # normal dag parameters
    schedule_interval="@weekly",
    start_date=datetime(2025, 1, 1),
    catchup=False,
    dag_id="dbt_gtfs",
    tags=["dbt", "gtfs"],
)

dbt_misc = DbtDag(
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
            "path:models/intermediate/transit_database+",
            "path:models/mart/audit+",
            "path:models/mart/benefits+",
            "path:models/mart/transit_database+",
            "path:models/mart/transit_database_latest+",
            "path:models/staging/amplitude+",
            "path:models/staging/audit+",
            "path:models/staging/hqta+",
            "path:models/staging/state_geoportal+",
            "path:models/staging/transit_database+",
        ],
    ),
    # normal dag parameters
    schedule_interval="@weekly",
    start_date=datetime(2025, 1, 1),
    catchup=False,
    dag_id="dbt_misc",
    tags=[
        "amplitude",
        "audit",
        "benefits",
        "dbt",
        "hqta",
        "state_geoportal",
        "transit_database",
    ],
)
