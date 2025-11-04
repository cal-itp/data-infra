from datetime import datetime

from airflow import DAG, XComArg
from airflow.operators.latest_only import LatestOnlyOperator

GTFS_SCHEDULE_FILES = [
    "agency.txt",
    "areas.txt",
    "attributions.txt",
    "calendar_dates.txt",
    "calendar.txt",
    "fare_attributes.txt",
    "fare_leg_rules.txt",
    "fare_media.txt",
    "fare_products.txt",
    "fare_rules.txt",
    "fare_transfer_rules.txt",
    "feed_info.txt",
    "frequencies.txt",
    "levels.txt",
    "pathways.txt",
    "routes.txt",
    "shapes.txt",
    "stop_areas.txt",
    "stop_times.txt",
    "stops.txt",
    "transfers.txt",
    "translations.txt",
    "trips.txt",
]

with DAG(
    dag_id="parse_and_validate_gtfs",
    tags=["gtfs"],
    # Every day at midnight
    schedule="0 0 * * *",
    start_date=datetime(2025, 11, 1),
    catchup=False,
):
    latest_only = LatestOnlyOperator(task_id="latest_only", depends_on_past=False)

    # tested
    # gs://calitp-airtable/california_transit__gtfs_datasets/dt=2025-10-29/ts=2025-10-29T02:00:00+00:00/gtfs_datasets.jsonl.gz
    dataset = AirtableToGCSOperator(
        task_id="california_transit_gtfs_datasets",
        air_base_id="appPnJWrQ7ui4UmIl",
        air_table_name="gtfs datasets",
        air_base_name="california_transit",
        bucket="{{ env_var('CALITP_BUCKET__AIRTABLE') }}",
    )

    # doesn't exist
    download_config = GTFSDatasetToDownloadConfigOperator.partial(
        task_id="convert_gtfs_datasets_to_download_configs",
        destination="{{ env_var('CALITP_BUCKET__DOWNLOAD_CONFIG') }}/gtfs_download_configs/ds={{ ds }}/ts={{ ts }}/configs.jsonl.gz",
    ).expand(source=XComArg(dataset))

    # doesn't exist
    commands = DownloadConfigToCommandOperator.partial(
        task_id="build_download_gtfs_schedule_commands"
    ).expand(source=XComArg(download_config))

    schedules = DownloadCommandToGCSOperator.partial(
        task_id="download_gtfs_schedule"
    ).expand(command=XComArg(commands))

    # needs command (like validate rt)
    BashOperator.partial(
        task_id=f"validate_gtfs_schedule",
        append_env=True,
        do_xcom_push=False,
    ).expand(bash_command=XComArg(schedules))

    # doesn't exist
    unzipped_schedules = GCSToUnzippedGCSOperator.partial(
        task_id="unzip_gtfs_schedule"
    ).expand(source=XComArg(schedules))

    for file in GTFS_SCHEDULE_FILES:
        # untested
        GtfsGcsToJsonlOperatorHourly.partial(task_id="parse_gtfs_schedule").expand(
            file=file, unzipped_schedule=XComArg(unzipped_schedules)
        )
