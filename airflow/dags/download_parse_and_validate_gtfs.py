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
from airflow.utils.trigger_rule import TriggerRule

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
    dag_id="download_parse_and_validate_gtfs",
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
        destination_bucket=os.getenv("CALITP_BUCKET__GTFS_DOWNLOAD_CONFIG"),
        destination_path="gtfs_download_configs/dt={{ ds }}/ts={{ ts }}/configs.jsonl.gz",
    )

    schedule_download_configs = GCSDownloadConfigFilterOperator(
        task_id="download_config_filter",
        feed_type="schedule",
        source_bucket=os.getenv("CALITP_BUCKET__GTFS_DOWNLOAD_CONFIG"),
        source_path="gtfs_download_configs/dt={{ ds }}/ts={{ ts }}/configs.jsonl.gz",
    )

    downloads = DownloadConfigToGCSOperator.partial(
        task_id="download_config_to_gcs",
        destination_bucket=os.getenv("CALITP_BUCKET__GTFS_SCHEDULE_RAW"),
        destination_path="schedule/dt={{ ds }}/ts={{ ts }}",
        results_path="download_schedule_feed_results/dt={{ ds }}/ts={{ ts }}",
        map_index_template="{{ task.download_config['name'] }}",
    ).expand(download_config=XComArg(schedule_download_configs))

    def create_validate_kwargs(download):
        return {
            "download_schedule_feed_results": download[
                "download_schedule_feed_results"
            ],
            "source_path": download["schedule_feed_path"],
            "destination_path": os.path.join(
                "validation_notices",
                "dt={{ ds }}",
                "ts={{ ts }}",
                f"base64_url={download['base64_url']}",
            ),
            "results_path": os.path.join(
                "validation_job_results",
                "dt={{ ds }}",
                "ts={{ ts }}",
                f"{download['base64_url']}.jsonl",
            ),
        }

    ValidateGTFSToGCSOperator.partial(
        task_id="validate_gtfs_to_gcs",
        destination_bucket=os.getenv("CALITP_BUCKET__GTFS_SCHEDULE_VALIDATION_HOURLY"),
        source_bucket=os.getenv("CALITP_BUCKET__GTFS_SCHEDULE_RAW"),
        trigger_rule=TriggerRule.ALL_DONE,
    ).expand_kwargs(XComArg(downloads).map(create_validate_kwargs))

    for schedule_file_type, schedule_filename in GTFS_SCHEDULE_FILENAMES.items():

        def create_unzip_kwargs(download):
            return {
                "download_schedule_feed_results": download[
                    "download_schedule_feed_results"
                ],
                "source_path": download["schedule_feed_path"],
                "base64_url": download["base64_url"],
                "destination_path": os.path.join(
                    schedule_filename,
                    "dt={{ ds }}",
                    "ts={{ ts }}",
                    f"base64_url={download['base64_url']}",
                    schedule_filename,
                ),
                "results_path": os.path.join(
                    "unzipping_results",
                    "dt={{ ds }}",
                    "ts={{ ts }}",
                    f"{download['base64_url']}_{schedule_filename}.jsonl",
                ),
            }

        unzipped_files = UnzipGTFSToGCSOperator.partial(
            task_id=f"unzip_{schedule_file_type}_to_gcs",
            filename=schedule_filename,
            source_bucket=os.getenv("CALITP_BUCKET__GTFS_SCHEDULE_RAW"),
            destination_bucket=os.getenv(
                "CALITP_BUCKET__GTFS_SCHEDULE_UNZIPPED_HOURLY"
            ),
            trigger_rule=TriggerRule.ALL_DONE,
        ).expand_kwargs(XComArg(downloads).map(create_unzip_kwargs))

        def create_parse_kwargs(unzipped_file):
            return {
                "unzip_results": unzipped_file["unzip_results"],
                "source_path": os.path.join(
                    schedule_filename,
                    "dt={{ ds }}",
                    "ts={{ ts }}",
                    f"base64_url={unzipped_file['base64_url']}",
                    schedule_filename,
                ),
                "results_path": os.path.join(
                    f"{schedule_filename}_parsing_results",
                    "dt={{ ds }}",
                    "ts={{ ts }}",
                    f"{unzipped_file['base64_url']}_{schedule_filename}.jsonl",
                ),
                "destination_path": os.path.join(
                    schedule_file_type,
                    "dt={{ ds }}",
                    "ts={{ ts }}",
                    f"base64_url={unzipped_file['base64_url']}",
                    f"{schedule_file_type}.jsonl.gz",
                ),
            }

        GTFSCSVToJSONLOperator.partial(
            task_id=f"convert_{schedule_file_type}_to_jsonl",
            source_bucket=os.getenv("CALITP_BUCKET__GTFS_SCHEDULE_UNZIPPED_HOURLY"),
            destination_bucket=os.getenv("CALITP_BUCKET__GTFS_SCHEDULE_PARSED_HOURLY"),
            trigger_rule=TriggerRule.ALL_DONE,
        ).expand_kwargs(XComArg(unzipped_files).map(create_parse_kwargs))

    latest_only >> download_config >> schedule_download_configs
