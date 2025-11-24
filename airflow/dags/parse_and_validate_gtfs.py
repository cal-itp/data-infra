import os
from datetime import datetime

from operators.bigquery_to_download_config_operator import (
    BigQueryToDownloadConfigOperator,
)
from operators.download_config_to_gcs_operator import DownloadConfigToGCSOperator
from operators.gcs_download_config_filter_operator import (
    GCSDownloadConfigFilterOperator,
)
from operators.gtfs_csv_to_jsonl_operator import GTFSCSVToJSONLOperator
from operators.unzip_gtfs_to_gcs_operator import UnzipGTFSToGCSOperator
from operators.validate_gtfs_to_gcs_operator import ValidateGTFSToGCSOperator

from airflow import DAG, XComArg
from airflow.operators.latest_only import LatestOnlyOperator

GTFS_SCHEDULE_FILENAMES = {
    "agency": "agency.txt",
    "areas": "areas.txt",
    "attributions": "attributions.txt",
    "calendar_dates": "calendar_dates.txt",
    "calendar": "calendar.txt",
    "fare_attributes": "fare_attributes.txt",
    "fare_leg_rules": "fare_leg_rules.txt",
    "fare_media": "fare_media.txt",
    "fare_products": "fare_products.txt",
    "fare_rules": "fare_rules.txt",
    "fare_transfer_rules": "fare_transfer_rules.txt",
    "feed_info": "feed_info.txt",
    "frequencies": "frequencies.txt",
    "levels": "levels.txt",
    "pathways": "pathways.txt",
    "routes": "routes.txt",
    "shapes": "shapes.txt",
    "stop_areas": "stop_areas.txt",
    "stop_times": "stop_times.txt",
    "stops": "stops.txt",
    "transfers": "transfers.txt",
    "translations": "translations.txt",
    "trips": "trips.txt",
}


with DAG(
    dag_id="parse_and_validate_gtfs",
    # Every day at midnight
    schedule="0 0 * * *",
    start_date=datetime(2025, 11, 1),
    catchup=False,
    tags=["gtfs"],
):
    latest_only = LatestOnlyOperator(task_id="latest_only", depends_on_past=False)

    download_config = BigQueryToDownloadConfigOperator(
        task_id="bigquery_to_download_config",
        dataset_name="staging",
        table_name="int_transit_database__gtfs_datasets_dim",
        destination_bucket="{{ env_var('CALITP_BUCKET__GTFS_DOWNLOAD_CONFIG') }}",
        destination_path="gtfs_download_configs/ds={{ ds }}/ts={{ ts }}/configs.jsonl.gz",
    )

    schedule_download_configs = GCSDownloadConfigFilterOperator.partial(
        task_id="download_config_filter",
        feed_type="schedule",
        source_bucket="{{ env_var('CALITP_BUCKET__GTFS_DOWNLOAD_CONFIG') }}",
    ).expand(source_path=XComArg(download_config))

    downloads = DownloadConfigToGCSOperator.partial(
        task_id="download_config_to_gcs",
        destination_bucket="{{ env_var('CALITP_BUCKET__GTFS_SCHEDULE_RAW') }}",
        destination_path="schedule/ds={{ ds }}/ts={{ ts }}",
        results_path="download_schedule_feed_results/ds={{ ds }}/ts={{ ts }}",
    ).expand(download_config=XComArg(schedule_download_configs))

    def create_validate_kwargs(download):
        return {
            "download_schedule_feed_results": download[
                "download_schedule_feed_results"
            ],
            "source_path": download["schedule_path"],
            "destination_path": os.path.join(
                "validation_notices",
                "ds={{ ds }}",
                "ts={{ ts }}",
                f"base64_url={download['base64_url']}",
            ),
            "results_path": os.path.join(
                "validation_job_results",
                "ds={{ ds }}",
                "ts={{ ts }}",
                f"{download['base64_url']}.jsonl",
            ),
        }

    ValidateGTFSToGCSOperator.partial(
        task_id="validate_gtfs_to_gcs",
        destination_bucket="{{ env_var('CALITP_BUCKET__GTFS_SCHEDULE_VALIDATION_HOURLY') }}",
        source_bucket="{{ env_var('CALITP_BUCKET__SCHEDULE_RAW') }}",
    ).expand_kwargs(XComArg(downloads).map(create_validate_kwargs))

    def create_unzip_kwargs(download):
        return {
            "download_schedule_feed_results": download[
                "download_schedule_feed_results"
            ],
            "source_path": download["schedule_path"],
            "base64_url": download["base64_url"],
            "destination_path": os.path.join(
                "{{ schedule_filename }}",
                "ds={{ ds }}",
                "ts={{ ts }}",
                f"base64_url={download['base64_url']}{{{{ schedule_filename }}}}",
            ),
            "results_path": os.path.join(
                "unzipping_results",
                "ds={{ ds }}",
                "ts={{ ts }}",
                f"{{ schedule_filename }}_{download['base64_url']}.jsonl",
            ),
        }

    def create_parse_kwargs(unzip):
        return {
            "unzip_results": unzip["unzip_results"],
            "filename": unzip["filename"],
            "source_path": os.path.join(
                "{{ schedule_file_type }}",
                "ds={{ ds }}",
                "ts={{ ts }}",
                f"base64_url={unzip['base64_url']}" "{{ schedule_file_type }}.jsonl.gz",
            ),
            "results_path": os.path.join(
                "{{ schedule_filename }}_parsing_results",
                "ds={{ ds }}",
                "ts={{ ts }}",
                f"{{ schedule_filename }}_{unzip['base64_url']}.jsonl",
            ),
        }

    for schedule_file_type, schedule_filename in GTFS_SCHEDULE_FILENAMES.items():
        unzipped_file = UnzipGTFSToGCSOperator.partial(
            task_id=f"unzip_gtfs_to_gcs_{schedule_file_type}",
            filename=schedule_filename,
            source_bucket="{{ env_var('CALITP_BUCKET__SCHEDULE_RAW') }}",
            destination_bucket="{{ env_var('CALITP_BUCKET__GTFS_SCHEDULE_UNZIPPED_HOURLY') }}",
        ).expand_kwargs(XComArg(downloads).map(create_validate_kwargs))

        GTFSCSVToJSONLOperator.partial(
            task_id=f"gtfs_csv_to_jsonl_{schedule_file_type}",
            source_bucket="{{ env_var('CALITP_BUCKET__GTFS_SCHEDULE_UNZIPPED_HOURLY') }}",
            destination_bucket="{{ env_var('CALITP_BUCKET__GTFS_SCHEDULE_PARSED_HOURLY') }}",
        ).expand_kwargs(XComArg(downloads).map(create_parse_kwargs))

    latest_only >> download_config
