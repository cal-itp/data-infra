import os
from datetime import datetime, timedelta

from dags import email_on_failure, log_failure_to_slack
from operators.bigquery_to_dict_operator import BigQueryToDictOperator
from operators.tides_bigquery_to_parquet_operator import TIDESBigQueryToParquetOperator

from airflow.decorators import dag, task


@dag(
    # Monday, Thursday at 10am PDT/9am PST (17pm UTC)
    schedule="0 17 * * 1,4",
    start_date=datetime(2026, 6, 10),
    catchup=False,
    tags=["tides"],
    default_args={
        "email": os.getenv("CALITP_NOTIFY_EMAIL"),
        "email_on_failure": email_on_failure(),
        "email_on_retry": False,
        "on_failure_callback": log_failure_to_slack,
    },
)
def generate_tides():
    @task
    def list_dates(
        data_interval_start=None, data_interval_end=None, **kwargs
    ) -> list[datetime]:
        return [
            data_interval_start + timedelta(days=d)
            for d in range((data_interval_end - data_interval_start).days)
        ]

    dates = list_dates()

    date_publication_feeds = BigQueryToDictOperator.partial(
        task_id="date_publication_feeds",
        retries=1,
        retry_delay=timedelta(seconds=10),
        dataset_name="mart_tides",
        table_name="tides_publication_feeds",
        select_columns=[
            "service_date",
            "organization_source_record_id",
            "feed_name",
            "base64_url",
        ],
        order_columns="service_date, feed_name",
        map_index_template="{{ task.filter_value }}",
    ).expand_kwargs(
        dates.map(
            lambda d: {
                "filter_column": "service_date",
                "filter_value": d.date().isoformat(),
            }
        )
    )

    @task
    def merge_publication_feeds(feeds=None, **kwargs):
        return [feed for date_feeds in feeds for feed in date_feeds]

    merged_publication_feeds = merge_publication_feeds(
        feeds=date_publication_feeds.output
    )

    export_vehicle_locations = TIDESBigQueryToParquetOperator.partial(
        task_id="export_vehicle_locations",
        retries=1,
        retry_delay=timedelta(seconds=10),
        ts="{{ ts }}",
        dataset_name="mart_tides",
        table_name="fct_tides_vehicle_locations",
        destination_bucket=os.environ.get("CALITP_BUCKET__TIDES"),
        destination_path_prefix="vehicle_locations/organization_source_record_id={{ task.organization_source_record_id }}/base64_url={{ task.base64_url }}/dt={{ task.dt }}/",
        report_path="vehicle_locations_outcomes/dt={{ task.dt }}/ts={{ ts }}/organization_source_record_id={{ task.organization_source_record_id }}/{{ task.base64_url }}_outcomes.jsonl",
        user_project=os.environ.get("GOOGLE_CLOUD_PROJECT"),
        map_index_template="{{ task.dt }} - {{ task.display_name }}",
    ).expand_kwargs(
        merged_publication_feeds.map(
            lambda feed: {
                "organization_source_record_id": feed["organization_source_record_id"],
                "base64_url": feed["base64_url"],
                "display_name": feed["feed_name"],
                "dt": feed["service_date"],
            }
        )
    )

    export_trips_performed = TIDESBigQueryToParquetOperator.partial(
        task_id="export_trips_performed",
        retries=1,
        retry_delay=timedelta(seconds=10),
        ts="{{ ts }}",
        dataset_name="mart_tides",
        table_name="fct_tides_trips_performed",
        destination_bucket=os.environ.get("CALITP_BUCKET__TIDES"),
        destination_path_prefix="trips_performed/organization_source_record_id={{ task.organization_source_record_id }}/base64_url={{ task.base64_url }}/dt={{ task.dt }}/",
        report_path="trips_performed_outcomes/dt={{ task.dt }}/ts={{ ts }}/organization_source_record_id={{ task.organization_source_record_id }}/{{ task.base64_url }}_outcomes.jsonl",
        user_project=os.environ.get("GOOGLE_CLOUD_PROJECT"),
        map_index_template="{{ task.dt }} - {{ task.display_name }}",
    ).expand_kwargs(
        merged_publication_feeds.map(
            lambda feed: {
                "organization_source_record_id": feed["organization_source_record_id"],
                "base64_url": feed["base64_url"],
                "display_name": feed["feed_name"],
                "dt": feed["service_date"],
            }
        )
    )

    (
        dates
        >> date_publication_feeds
        >> merged_publication_feeds
        >> (export_vehicle_locations, export_trips_performed)
    )


generate_tides = generate_tides()
