import os
from datetime import datetime, timedelta

from dags import email_on_failure, log_failure_to_slack
from operators.bigquery_to_parquet_operator import BigQueryToParquetOperator

from airflow import DAG
from airflow.operators.latest_only import LatestOnlyOperator
from airflow.providers.google.cloud.operators.bigquery import BigQueryGetDataOperator

with DAG(
    dag_id="parse_tides",
    tags=["tides"],
    # 12pm UTC (5am PDT/4am PST) every day
    schedule="0 12 * * *",
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

    vehicle_location_agencies = BigQueryGetDataOperator(
        task_id="list_vehicle_location_agencies",
        retries=1,
        retry_delay=timedelta(seconds=10),
        dataset_id="staging",
        table_id="tides_publication_keys",
        selected_fields="vehicle_positions_source_record_id,agency_name",
        as_dict=True,
        # max_results=100, #set max results if needed
        gcp_conn_id="google_cloud_default",
    )

    export_vehicle_locations_to_parquet = BigQueryToParquetOperator.partial(
        task_id="export_vehicle_locations_to_parquet",
        retries=1,
        retry_delay=timedelta(seconds=10),
        dt="{{ dt }}",
        ts="{{ ts }}",
        dataset_name="mart_tides",
        table_name="fct_tides_vehicle_locations",
        source_record_name="gtfs_dataset_key",
        destination_bucket=os.environ.get("CALITP_BUCKET__TIDES"),
        destination_path_prefix="vehicle_locations/dt={{ ds }}/ts={{ ts }}/gtfs_dataset_key={{ task.source_record_id }}/",
        report_path="vehicle_location_outcomes/dt={{ ds }}/ts={{ ts }}/{{ task.source_record_id }}_results.jsonl",
        map_index_template="{{ task.display_name }}",
        gcp_conn_id="google_cloud_default",
    ).expand_kwargs(
        vehicle_location_agencies.output.map(
            lambda agency: {
                "source_record_id": agency["vehicle_positions_source_record_id"],
                "display_name": agency["agency_name"],
            }
        )
    )

    latest_only >> vehicle_location_agencies >> export_vehicle_locations_to_parquet
