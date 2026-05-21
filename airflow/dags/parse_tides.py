import os
from datetime import datetime, timedelta

from dags import email_on_failure, log_failure_to_slack
from operators.bigquery_to_dict_operator import BigQueryToDictOperator
from operators.tides_bigquery_to_parquet_operator import TIDESBigQueryToParquetOperator

from airflow.decorators import dag
from airflow.operators.latest_only import LatestOnlyOperator


@dag(
    # Monday, Thursday at 10am PDT/9am PST (17pm UTC)
    schedule="0 17 * * 1,4",
    start_date=datetime(2025, 12, 1),
    catchup=False,  # Change to True when tests are done to run all days
    tags=["tides"],
    default_args={
        "email": os.getenv("CALITP_NOTIFY_EMAIL"),
        "email_on_failure": email_on_failure(),
        "email_on_retry": False,
        "on_failure_callback": log_failure_to_slack,
    },
)
def parse_tides():
    latest_only = LatestOnlyOperator(task_id="latest_only", depends_on_past=False)

    vehicle_location_agencies = BigQueryToDictOperator(
        task_id="list_vehicle_location_feeds",
        retries=1,
        retry_delay=timedelta(seconds=10),
        dataset_name="mart_tides",
        table_name="tides_publication_feeds",
        select_columns=[
            "dt",
            "organization_source_record_id",
            "feed_name",
            "base64_url",
        ],
        filter_date_column="dt",
        filter_date_start="{{ macros.ds_add(ds, -3) }}",
        filter_date_end="{{ ds }}",
        order_columns="dt, feed_name",
    )

    export_vehicle_locations_to_parquet = TIDESBigQueryToParquetOperator.partial(
        task_id="export_vehicle_locations_to_parquet",
        retries=1,
        retry_delay=timedelta(seconds=10),
        ts="{{ ts }}",
        dataset_name="mart_tides",
        table_name="fct_tides_vehicle_locations",
        destination_bucket=os.environ.get("CALITP_BUCKET__TIDES"),
        destination_path_prefix="vehicle_locations/organization_source_record_id={{ task.organization_source_record_id }}/base64_url={{ task.base64_url }}/dt={{ task.dt }}/",
        report_path="vehicle_location_outcomes/dt={{ task.dt }}/ts={{ ts }}/organization_source_record_id={{ task.organization_source_record_id }}/{{ task.base64_url }}_outcomes.jsonl",
        map_index_template="{{ task.dt }} - {{ task.display_name }}",
    ).expand_kwargs(
        vehicle_location_agencies.output.map(
            lambda agency: {
                "organization_source_record_id": agency[
                    "organization_source_record_id"
                ],
                "base64_url": agency["base64_url"],
                "display_name": agency["feed_name"],
                "dt": agency["dt"],
            }
        )
    )

    latest_only >> vehicle_location_agencies >> export_vehicle_locations_to_parquet


parse_tides = parse_tides()
