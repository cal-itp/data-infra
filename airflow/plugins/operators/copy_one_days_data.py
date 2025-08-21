# from __future__ import annotations
# import os
from datetime import datetime

from airflow import DAG
from airflow.providers.google.cloud.transfers.gcs_to_gcs import GCSToGCSOperator

# from cosmos import DbtTaskGroup, ProfileConfig, ProjectConfig, RenderConfig
# from cosmos.constants import TestBehavior


# Define buckets
# SOURCE_RT_BUCKET = "calitp-gtfs-rt-raw-v2"
# DEST_RT_BUCKET = "calitp-staging-gtfs-rt-raw-v2"
# SOURCE_SCHEDULE_BUCKET = "calitp-gtfs-schedule-raw-v2"
# DEST_SCHEDULE_BUCKET = "calitp-staging-gtfs-schedule-raw-v2"
# SOURCE_AIRTABLE_BUCKET = "calitp-airtable"
# SOURCE_AIRTABLE_BUCKET =
DEST_AIRTABLE_BUCKET = "test-calitp-airtable"
SOURCE_AIRTABLE_BUCKET = "calitp-staging-airtable"

# Using Airflow's logical date `{{ ds }}` is the standard way to get the
# execution date for a daily DAG. This will format to 'YYYY-MM-DD'.
# YESTERDAY_PARTITION = "dt={{ ds }}"
YESTERDAY_PARTITION = "dt=2025-06-15"
with DAG(
    dag_id="copy_production_data_to_staging",
    tags=["maintenance", "gcs", "daily"],
    schedule="@daily",
    start_date=datetime(2025, 8, 19),
    # Run daily to copy the previous day's data.
    catchup=False,
    doc_md="""
    ### Copy Yesterday's Production Data to Staging

    This DAG copies the previous day's raw data from production GCS buckets
    to staging GCS buckets. It is useful for keeping the staging environment
    up-to-date with production data.

    It runs one copy job per source bucket for efficiency.
    """,
) as dag:
    # --- Task 1: Copy all GTFS-RT data types for yesterday ---
    # The source_objects parameter takes a list of all prefixes to copy
    # rt_data_types_to_copy = [
    #     f"trip_updates/{YESTERDAY_PARTITION}/*",
    #     f"vehicle_positions/{YESTERDAY_PARTITION}/*",
    #     f"service_alerts/{YESTERDAY_PARTITION}/*",
    # ]

    # copy_gtfs_rt_task = GCSToGCSOperator(
    #     task_id="copy_gtfs_rt_data",
    #     source_bucket=SOURCE_RT_BUCKET,
    #     source_objects=rt_data_types_to_copy,
    #     destination_bucket=DEST_RT_BUCKET,
    #     # The destination object is the root, so the source paths are preserved
    #     destination_object="/",
    #     match_glob=True,
    # )

    # # --- Task 2: Copy all GTFS-Schedule data types for yesterday ---
    # schedule_data_types_to_copy = [
    #     f"schedule/{YESTERDAY_PARTITION}/*",
    #     f"download_schedule_feed_results/{YESTERDAY_PARTITION}/*",
    # ]

    # copy_gtfs_schedule_task = GCSToGCSOperator(
    #     task_id="copy_gtfs_schedule_data",
    #     source_bucket=SOURCE_SCHEDULE_BUCKET,
    #     source_objects=schedule_data_types_to_copy,
    #     destination_bucket=DEST_SCHEDULE_BUCKET,
    #     destination_object="/",
    #     match_glob=True,
    # )

    # This remains a full bucket copy as it is not partitioned by date.
    copy_airtable_task = GCSToGCSOperator(
        task_id="copy_airtable_data",
        source_bucket=SOURCE_AIRTABLE_BUCKET,
        source_object=f"**/{YESTERDAY_PARTITION}/*",  # Copy all objects
        replace=False,
        destination_bucket=DEST_AIRTABLE_BUCKET,
        # destination_object=f"",
        match_glob=True,
    )
