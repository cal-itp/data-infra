import os
from datetime import datetime

from dags import email_on_failure, log_failure_to_slack
from operators.dbt_bigquery_to_parquet_gcs_operator import (
    DBTBigQueryToParquetGCSOperator,
)
from operators.tides_metadata_sidecar_operator import TidesMetadataSidecarOperator

from airflow import DAG
from airflow.operators.latest_only import LatestOnlyOperator

with DAG(
    dag_id="publish_tides",
    tags=["tides", "open-data"],
    # First of each month, 00:00 UTC
    schedule="0 0 1 * *",
    start_date=datetime(2026, 5, 1),
    catchup=False,
    default_args={
        "email": os.getenv("CALITP_NOTIFY_EMAIL"),
        "email_on_failure": email_on_failure(),
        "email_on_retry": False,
        "on_failure_callback": log_failure_to_slack,
    },
):
    latest_only = LatestOnlyOperator(task_id="latest_only", depends_on_past=False)

    vehicle_locations_export = DBTBigQueryToParquetGCSOperator(
        task_id="vehicle_locations_export",
        destination_bucket_name=os.getenv("CALITP_BUCKET__TIDES_PUBLISH"),
        destination_object_name=(
            "tides/v1/vehicle_locations/"
            "gtfs_dataset_key=*/service_date=*/data*.parquet"
        ),
        dataset_id="mart_tides",
        table_name="fct_tides_vehicle_locations",
    )

    metadata_sidecar = TidesMetadataSidecarOperator(
        task_id="metadata_sidecar",
        destination_bucket_name=os.getenv("CALITP_BUCKET__TIDES_PUBLISH"),
        destination_object_name="_metadata.jsonl",
    )

    latest_only >> vehicle_locations_export >> metadata_sidecar
