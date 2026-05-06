import os
from datetime import datetime

from dags import email_on_failure, log_failure_to_slack
from operators.dbt_bigquery_to_parquet_gcs_operator import (
    DBTBigQueryToParquetGCSOperator,
)
from operators.tides_metadata_sidecar_operator import TidesMetadataSidecarOperator
from operators.validate_tides_to_gcs_operator import ValidateTIDESToGCSOperator

from airflow import DAG
from airflow.decorators import task
from airflow.operators.latest_only import LatestOnlyOperator
from airflow.providers.google.cloud.hooks.bigquery import BigQueryHook
from airflow.utils.trigger_rule import TriggerRule

VEHICLE_LOCATIONS_TIDES_DATASET = "mart_tides"
VEHICLE_LOCATIONS_TIDES_TABLE = "fct_tides_vehicle_locations"

VEHICLE_LOCATIONS_SCHEMA_URL = (
    "https://raw.githubusercontent.com/TIDES-transit/TIDES/main/spec/"
    "vehicle_locations.schema.json"
)


def feed_url_for(table_name: str, gtfs_dataset_key: str) -> str:
    """Stable identifier for the published TIDES slice. Base64 of this string
    is the join key across outcome envelopes and partition paths."""
    return f"warehouse://{table_name}/gtfs_dataset_key={gtfs_dataset_key}"


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
        dataset_id=VEHICLE_LOCATIONS_TIDES_DATASET,
        table_name=VEHICLE_LOCATIONS_TIDES_TABLE,
    )

    @task(task_id="list_publication_targets")
    def list_publication_targets() -> list[dict]:
        client = BigQueryHook(
            gcp_conn_id="google_cloud_default",
            location=os.getenv("CALITP_BQ_LOCATION"),
        ).get_client()
        query = f"""
        SELECT gtfs_dataset_key, agency_name
        FROM `{VEHICLE_LOCATIONS_TIDES_DATASET}.tides_publication_keys`
        ORDER BY agency_name
        """
        return [
            {
                "gtfs_dataset_key": row["gtfs_dataset_key"],
                "agency_name": row["agency_name"],
            }
            for row in client.query(query).result()
        ]

    publication_targets = list_publication_targets()

    @task(map_index_template="{{ task.op_kwargs['target']['agency_name'] }}")
    def build_validate_kwargs(target: dict, run_dt: str, run_ts: str) -> dict:
        return {
            "dt": run_dt,
            "ts": run_ts,
            "dataset_id": VEHICLE_LOCATIONS_TIDES_DATASET,
            "table_name": VEHICLE_LOCATIONS_TIDES_TABLE,
            # Validate yesterday's service_date for the monthly run; the
            # warehouse partition is closed by the time the DAG fires.
            "service_date": "{{ macros.ds_add(data_interval_end | ds, -1) }}",
            "gtfs_dataset_key": target["gtfs_dataset_key"],
            "feed_name": target["agency_name"],
            "feed_url": feed_url_for(
                VEHICLE_LOCATIONS_TIDES_TABLE, target["gtfs_dataset_key"]
            ),
            "schema_url": VEHICLE_LOCATIONS_SCHEMA_URL,
            "destination_bucket": os.getenv("CALITP_BUCKET__TIDES_PUBLISH"),
            "outcome_path_prefix": "validation_outcomes/vehicle_locations",
        }

    validate_kwargs = build_validate_kwargs.partial(
        run_dt="{{ data_interval_end | ds }}",
        run_ts="{{ data_interval_end | ts }}",
    ).expand(target=publication_targets)

    vehicle_locations_validate = ValidateTIDESToGCSOperator.partial(
        task_id="vehicle_locations_validate",
        map_index_template="{{ task.feed_name }}",
        trigger_rule=TriggerRule.ALL_DONE,
    ).expand_kwargs(validate_kwargs)

    metadata_sidecar = TidesMetadataSidecarOperator(
        task_id="metadata_sidecar",
        destination_bucket_name=os.getenv("CALITP_BUCKET__TIDES_PUBLISH"),
        destination_object_name="_metadata.jsonl",
        trigger_rule=TriggerRule.ALL_DONE,
    )

    (
        latest_only
        >> vehicle_locations_export
        >> vehicle_locations_validate
        >> metadata_sidecar
    )
