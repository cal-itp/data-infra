import os
from datetime import datetime, timedelta

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

from airflow import XComArg
from airflow.decorators import dag, task
from airflow.operators.dummy import DummyOperator
from airflow.operators.latest_only import LatestOnlyOperator
from airflow.providers.google.cloud.hooks.gcs import GCSHook
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


@task.branch()
def gcs_branch(bucket_name, object_name, present, missing):
    exists = GCSHook().exists(
        bucket_name=bucket_name.removeprefix("gs://"), object_name=object_name
    )
    return present if exists else missing


@dag(
    # 3am UTC (8am PDT/7am PST) every day - should run after 'airtable_loader_v2'
    schedule="0 3 * * *",
    start_date=datetime(2026, 1, 6),
    catchup=False,
    tags=["gtfs"],
    default_args={
        "email": os.getenv("CALITP_NOTIFY_EMAIL"),
        "email_on_failure": True,
        "email_on_retry": False,
    },
)
def download_parse_and_validate_gtfs():
    latest_only = LatestOnlyOperator(task_id="latest_only", depends_on_past=False)

    download_config_exists = gcs_branch.override(task_id="download_config_exists")(
        bucket_name=os.getenv("CALITP_BUCKET__GTFS_DOWNLOAD_CONFIG"),
        object_name="gtfs_download_configs/dt={{ data_interval_end | ds }}/ts={{ data_interval_end | ts }}/configs.jsonl.gz",
        present="skip_bigquery_to_download_config",
        missing="bigquery_to_download_config",
    )

    skip_download_config = DummyOperator(task_id="skip_bigquery_to_download_config")

    download_config = BigQueryToDownloadConfigOperator(
        task_id="bigquery_to_download_config",
        retries=1,
        retry_delay=timedelta(seconds=10),
        dataset_name="staging",
        table_name="int_gtfs_datasets",
        ts="{{ data_interval_end | ts }}",
        destination_bucket=os.getenv("CALITP_BUCKET__GTFS_DOWNLOAD_CONFIG"),
        destination_path="gtfs_download_configs/dt={{ data_interval_end | ds }}/ts={{ data_interval_end | ts }}/configs.jsonl.gz",
    )

    schedule_download_configs = GCSDownloadConfigFilterOperator(
        task_id="download_config_filter",
        limit=None,
        retries=1,
        retry_delay=timedelta(seconds=10),
        feed_type="schedule",
        source_bucket=os.getenv("CALITP_BUCKET__GTFS_DOWNLOAD_CONFIG"),
        source_path="gtfs_download_configs/dt={{ data_interval_end | ds }}/ts={{ data_interval_end | ts }}/configs.jsonl.gz",
        trigger_rule=TriggerRule.NONE_FAILED,
    )

    downloads = DownloadConfigToGCSOperator.partial(
        task_id="download_config_to_gcs",
        retries=1,
        retry_delay=timedelta(seconds=10),
        dt="{{ dag_run.start_date | ds }}",
        ts="{{ dag_run.start_date | ts }}",
        destination_bucket=os.getenv("CALITP_BUCKET__GTFS_SCHEDULE_RAW"),
        destination_path="schedule/dt={{ dag_run.start_date | ds }}/ts={{ dag_run.start_date | ts }}",
        results_path="download_schedule_feed_results/dt={{ dag_run.start_date | ds }}/ts={{ dag_run.start_date | ts }}",
        map_index_template="{{ task.download_config['name'] }}",
        pool="schedule_download_pool",
    ).expand(download_config=XComArg(schedule_download_configs))

    def create_validate_kwargs(download):
        return {
            "dt": download["dt"],
            "ts": download["ts"],
            "download_schedule_feed_results": download[
                "download_schedule_feed_results"
            ],
            "source_path": download["schedule_feed_path"],
            "destination_path": os.path.join(
                "validation_notices",
                f"dt={download['dt']}",
                f"ts={download['ts']}",
                f"base64_url={download['base64_url']}",
            ),
            "results_path": os.path.join(
                "validation_job_results",
                f"dt={download['dt']}",
                f"ts={download['ts']}",
                f"{download['base64_url']}.jsonl",
            ),
        }

    validate = ValidateGTFSToGCSOperator.partial(
        task_id="validate_gtfs_to_gcs",
        retries=1,
        retry_delay=timedelta(seconds=10),
        destination_bucket=os.getenv("CALITP_BUCKET__GTFS_SCHEDULE_VALIDATION_HOURLY"),
        source_bucket=os.getenv("CALITP_BUCKET__GTFS_SCHEDULE_RAW"),
        map_index_template="{{ task.download_schedule_feed_results['config']['name'] }}",
        trigger_rule=TriggerRule.ALL_DONE,
        pool="schedule_validate_pool",
    ).expand_kwargs(downloads.output.map(create_validate_kwargs))

    def unzip_files_kwargs(download):
        return {
            "dt": download["dt"],
            "ts": download["ts"],
            "download_schedule_feed_results": download[
                "download_schedule_feed_results"
            ],
            "source_path": download["schedule_feed_path"],
            "base64_url": download["base64_url"],
            "destination_path_fragment": os.path.join(
                f"dt={download['dt']}",
                f"ts={download['ts']}",
                "base64_url={{ task.base64_url }}",
            ),
            "results_path": os.path.join(
                "unzipping_results",
                f"dt={download['dt']}",
                f"ts={download['ts']}",
                "{{ task.base64_url }}.jsonl",
            ),
        }

    unzip = UnzipGTFSToGCSOperator.partial(
        task_id="unzip_to_gcs",
        retries=1,
        retry_delay=timedelta(seconds=10),
        filenames=list(GTFS_SCHEDULE_FILENAMES.keys()),
        source_bucket=os.getenv("CALITP_BUCKET__GTFS_SCHEDULE_RAW"),
        destination_bucket=os.getenv("CALITP_BUCKET__GTFS_SCHEDULE_UNZIPPED_HOURLY"),
        map_index_template="{{ task.download_schedule_feed_results['config']['name'] }}",
        trigger_rule=TriggerRule.ALL_DONE,
        pool="schedule_unzip_pool",
    ).expand_kwargs(downloads.output.map(unzip_files_kwargs))

    def list_unzipped_files(unzipped_file):
        return {
            "dt": unzipped_file["dt"],
            "ts": unzipped_file["ts"],
            "unzip_results": unzipped_file["unzip_results"],
            "source_path_fragment": unzipped_file["destination_path_fragment"],
            "results_path_fragment": os.path.join(
                f"dt={unzipped_file['dt']}",
                f"ts={unzipped_file['ts']}",
                f"{unzipped_file['base64_url']}.jsonl",
            ),
            "destination_path_fragment": os.path.join(
                f"dt={unzipped_file['dt']}",
                f"ts={unzipped_file['ts']}",
                f"base64_url={unzipped_file['base64_url']}",
            ),
        }

    convert = GTFSCSVToJSONLOperator.partial(
        task_id="convert_to_jsonl",
        retries=1,
        retry_delay=timedelta(seconds=10),
        source_bucket=os.getenv("CALITP_BUCKET__GTFS_SCHEDULE_UNZIPPED_HOURLY"),
        destination_bucket=os.getenv("CALITP_BUCKET__GTFS_SCHEDULE_PARSED_HOURLY"),
        map_index_template="{{ task.unzip_results['extract']['config']['name'] }}",
        trigger_rule=TriggerRule.ALL_DONE,
        pool="schedule_parse_pool",
    ).expand_kwargs(unzip.output.map(list_unzipped_files))

    (latest_only >> download_config_exists >> (download_config, skip_download_config))

    ((download_config, skip_download_config) >> schedule_download_configs)

    (schedule_download_configs >> downloads >> (validate, (unzip >> convert)))


download_parse_and_validate_gtfs_instance = download_parse_and_validate_gtfs()
