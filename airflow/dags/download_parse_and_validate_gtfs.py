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
    "agency.txt": "agency",
    "areas.txt": "areas",
    "attributions.txt": "attributions",
    "calendar_dates.txt": "calendar_dates",
    "calendar.txt": "calendar",
    "fare_attributes.txt": "fare_attributes",
    "fare_leg_rules.txt": "fare_leg_rules",
    "fare_media.txt": "fare_media",
    "fare_products.txt": "fare_products",
    "fare_rules.txt": "fare_rules",
    "fare_transfer_rules.txt": "fare_transfer_rules",
    "feed_info.txt": "feed_info",
    "frequencies.txt": "frequencies",
    "levels.txt": "levels",
    "pathways.txt": "pathways",
    "routes.txt": "routes",
    "shapes.txt": "shapes",
    "stop_areas.txt": "stop_areas",
    "stop_times.txt": "stop_times",
    "stops.txt": "stops",
    "transfers.txt": "transfers",
    "translations.txt": "translations",
    "trips.txt": "trips",
}


with DAG(
    dag_id="download_parse_and_validate_gtfs",
    # Every day at midnight
    schedule="0 0 * * *",
    start_date=datetime(2025, 11, 1),
    catchup=False,
    tags=["gtfs"],
    user_defined_macros={"basename": os.path.basename},
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
        limit=None,
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
        map_index_template="{{ task.download_schedule_feed_results['config']['name'] }}",
        trigger_rule=TriggerRule.ALL_DONE,
    ).expand_kwargs(XComArg(downloads).map(create_validate_kwargs))

    def unzip_files_kwargs(download):
        return {
            "download_schedule_feed_results": download[
                "download_schedule_feed_results"
            ],
            "source_path": download["schedule_feed_path"],
            "base64_url": download["base64_url"],
        }

    unzipped_files = UnzipGTFSToGCSOperator.partial(
        task_id="unzip_to_gcs",
        filenames=list(GTFS_SCHEDULE_FILENAMES.keys()),
        source_bucket=os.getenv("CALITP_BUCKET__GTFS_SCHEDULE_RAW"),
        destination_bucket=os.getenv("CALITP_BUCKET__GTFS_SCHEDULE_UNZIPPED_HOURLY"),
        destination_path_fragment="dt={{ ds }}/ts={{ ts }}/base64_url={{ task.base64_url }}",
        results_path="unzipping_results/dt={{ ds }}/ts={{ ts }}/{{ task.base64_url }}.jsonl",
        map_index_template="{{ task.download_schedule_feed_results['config']['name'] }}",
        trigger_rule=TriggerRule.ALL_DONE,
    ).expand_kwargs(downloads.output.map(unzip_files_kwargs))

    def list_unzipped_files(unzipped_file):
        return {
            "unzip_results": unzipped_file["unzip_results"],
            "source_path_fragment": os.path.join(
                "dt={{ ds }}",
                "ts={{ ts }}",
                f"base64_url={unzipped_file['base64_url']}",
            ),
            "results_path_fragment": os.path.join(
                "dt={{ ds }}",
                "ts={{ ts }}",
                f"{unzipped_file['base64_url']}.jsonl",
            ),
            "destination_path_fragment": os.path.join(
                "dt={{ ds }}",
                "ts={{ ts }}",
                f"base64_url={unzipped_file['base64_url']}",
            ),
        }

    GTFSCSVToJSONLOperator.partial(
        task_id="convert_to_jsonl",
        source_bucket=os.getenv("CALITP_BUCKET__GTFS_SCHEDULE_UNZIPPED_HOURLY"),
        destination_bucket=os.getenv("CALITP_BUCKET__GTFS_SCHEDULE_PARSED_HOURLY"),
        map_index_template="{{ task.unzip_results['extract']['config']['name'] }}",
        trigger_rule=TriggerRule.ALL_DONE,
    ).expand_kwargs(XComArg(unzipped_files).map(list_unzipped_files))

    latest_only >> download_config >> schedule_download_configs
