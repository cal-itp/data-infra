import json
import logging
import os
from datetime import datetime, timedelta

from dags import email_on_failure, log_failure_to_slack
from operators.littlepay_psv_to_jsonl_operator import LittlepayPSVToJSONLOperator
from operators.littlepay_s3_to_gcs_operator import LittlepayS3ToGCSOperator

from airflow.decorators import dag, task, task_group
from airflow.exceptions import AirflowSkipException
from airflow.operators.latest_only import LatestOnlyOperator
from airflow.providers.amazon.aws.hooks.s3 import S3Hook
from airflow.providers.amazon.aws.operators.s3 import S3ListOperator
from airflow.providers.google.cloud.hooks.gcs import GCSHook
from airflow.utils.trigger_rule import TriggerRule

logger = logging.getLogger(__name__)

LITTLEPAY_TRANSIT_PROVIDER_CONFIG = {
    "atn": {
        "bucket": "littlepay-datafeed-prod-atn-5c319c40",
        "prefix": "atn/v3",
    },
    "ccjpa": {
        "bucket": "littlepay-datafeed-prod-ccjpa-5ca349d0",
        "prefix": "ccjpa/v3",
    },
    "clean-air-express": {
        "bucket": "littlepay-datafeed-prod-cal-itp-5b3f9b20",
        "prefix": "cal-itp/v3",
    },
    "eldorado-transit": {
        "bucket": "littlepay-datafeed-prod-eldorado-transit-fae490a0",
        "prefix": "eldorado-transit/v3",
    },
    "humboldt-transit-authority": {
        "bucket": "littlepay-datafeed-prod-humboldt-transit-aut-5c476e30",
        "prefix": "humboldt-transit-authority/v3",
    },
    "lake-transit-authority": {
        "bucket": "littlepay-datafeed-prod-lake-transit-authori-5cb54b30",
        "prefix": "lake-transit-authority/v3",
    },
    "mendocino-transit-authority": {
        "bucket": "littlepay-datafeed-prod-mendocino-transit-au-596cfe00",
        "prefix": "mendocino-transit-authority/v3",
    },
    "mst": {
        "bucket": "littlepay-datafeed-prod-mst-5aa508d0",
        "prefix": "mst/v3",
    },
    "nevada-county-connects": {
        "bucket": "littlepay-datafeed-prod-nevada-county-connec-7c9479e0",
        "prefix": "nevada-county-connects/v3",
    },
    "redwood-coast-transit": {
        "bucket": "littlepay-datafeed-prod-redwood-coast-transi-5c4dfde0",
        "prefix": "redwood-coast-transit/v3",
    },
    "roseville-transit": {
        "bucket": "littlepay-datafeed-prod-roseville-transit-3a6af910",
        "prefix": "roseville-transit/v3",
    },
    "sacrt": {
        "bucket": "littlepay-datafeed-prod-sacrt-56af2970",
        "prefix": "sacrt/v3",
    },
    "sbmtd": {
        "bucket": "littlepay-datafeed-prod-sbmtd-58599230",
        "prefix": "sbmtd/v3",
    },
    "scmetro": {
        "bucket": "littlepay-datafeed-prod-scmetro-96277fd0",
        "prefix": "scmetro/v3",
    },
    "scrra": {"bucket": "littlepay-datafeed-prod-scrra-ccb1a1b0", "prefix": "scrra/v3"},
    "slo-transit": {
        "bucket": "littlepay-datafeed-prod-slo-transit-979e5390",
        "prefix": "slo-transit/v3",
    },
    "slorta": {
        "bucket": "littlepay-datafeed-prod-slorta-991b7db0",
        "prefix": "slorta/v3",
    },
    "yolobus": {
        "bucket": "littlepay-datafeed-prod-yolobus-3d71d410",
        "prefix": "yolobus/v3",
    },
}


def parse_kwargs(file):
    # TEMPORARY: CCJPA refunds PSVs are repeatedly malformed and break the pipeline.
    # They are still downloaded, but parsing is skipped. Remove this check to revert.
    if file["provider"] == "ccjpa" and file["filename"].endswith("refunds.psv"):
        raise AirflowSkipException(f"Skipping parse of {file['filename']} for ccjpa")

    return {
        "entity": file["entity"],
        "provider": file["provider"],
        "filename": file["filename"],
        "ts": file["ts"],
        "source_path": file["destination_path"],
    }


@task
def filter_existing_littlepay_files(
    source_paths: list[str],
    provider: str,
    source_bucket: str,
    source_prefix: str,
    aws_conn_id: str,
    destination_bucket: str,
) -> list[str]:
    """Return S3 files that are new or changed since their last GCS copy."""
    s3_hook = S3Hook(aws_conn_id=aws_conn_id)
    gcs_hook = GCSHook()
    bucket_name = destination_bucket.removeprefix("gs://")

    # Retrieve current S3 metadata using paginated listings.
    s3_objects = {}
    paginator = s3_hook.get_conn().get_paginator("list_objects_v2")

    for page in paginator.paginate(
        Bucket=source_bucket,
        Prefix=source_prefix,
    ):
        for obj in page.get("Contents", []):
            s3_objects[obj["Key"]] = obj

    paths_to_copy = []

    for source_path in source_paths:
        current_s3 = s3_objects.get(source_path)

        # Do not create a copy task for a source that has disappeared.
        if current_s3 is None:
            logger.warning("S3 source no longer exists: %s", source_path)
            continue

        parts = source_path.split("/")
        if len(parts) < 3:
            paths_to_copy.append(source_path)
            continue

        entity = parts[2]
        filename = os.path.basename(source_path)
        prefix = f"{entity}/instance={provider}/filename={filename}"

        prior_objects = (
            gcs_hook.list(
                bucket_name=bucket_name,
                prefix=prefix,
                match_glob=f"**/{filename}",
            )
            or []
        )

        if not prior_objects:
            paths_to_copy.append(source_path)
            continue

        # Match PriorArtifact.retrieve(): use the newest GCS artifact.
        latest_object = max(
            prior_objects,
            key=lambda name: gcs_hook.get_blob_update_time(
                bucket_name=bucket_name,
                object_name=name,
            ),
        )

        metadata = (
            gcs_hook.get_metadata(
                bucket_name=bucket_name,
                object_name=latest_object,
            )
            or {}
        )

        try:
            artifact_metadata = json.loads(
                metadata.get("PARTITIONED_ARTIFACT_METADATA", "{}")
            )
            previous_s3 = artifact_metadata.get("s3object") or {}
        except (TypeError, ValueError, AttributeError):
            previous_s3 = {}

        # Preserve the existing operator's modification checks.
        unchanged = current_s3["LastModified"].isoformat() == previous_s3.get(
            "LastModified"
        ) and current_s3["ETag"] == previous_s3.get("ETag")

        if not unchanged:
            paths_to_copy.append(source_path)

    logger.info(
        "Littlepay provider %s: %d source files, %d to copy",
        provider,
        len(source_paths),
        len(paths_to_copy),
    )

    return paths_to_copy


@dag(
    # 12pm UTC (5am PDT/4am PST) every day
    schedule="0 12 * * *",
    start_date=datetime(2026, 4, 1),
    catchup=False,
    tags=["payments", "littlepay"],
    default_args={
        "email": os.getenv("CALITP_NOTIFY_EMAIL"),
        "email_on_failure": email_on_failure(),
        "email_on_retry": False,
        "on_failure_callback": log_failure_to_slack,
    },
    user_defined_macros={
        "basename": os.path.basename,
        "splitext": os.path.splitext,
    },
)
def download_and_parse_littlepay():
    latest_only = LatestOnlyOperator(task_id="latest_only", depends_on_past=False)

    provider_groups = []
    for provider, config in LITTLEPAY_TRANSIT_PROVIDER_CONFIG.items():

        @task_group(group_id=provider)
        def provider_group(provider=provider, config=config):
            source_paths = S3ListOperator(
                task_id=f"{provider}_littlepay_list",
                retries=1,
                retry_delay=timedelta(seconds=10),
                prefix=config["prefix"],
                bucket=config["bucket"],
                aws_conn_id=f"aws_{provider}",
                pool="littlepay_list_pool",
            )

            files_to_copy = filter_existing_littlepay_files(
                source_paths=source_paths.output,
                provider=provider,
                source_bucket=config["bucket"],
                source_prefix=config["prefix"],
                aws_conn_id=f"aws_{provider}",
                destination_bucket=os.environ.get("CALITP_BUCKET__LITTLEPAY_RAW_V3"),
            )

            synced_files = LittlepayS3ToGCSOperator.partial(
                task_id=f"{provider}_littlepay_copy",
                retries=1,
                retry_delay=timedelta(seconds=10),
                provider=provider,
                aws_conn_id=f"aws_{provider}",
                entity="{{ task.source_path.split('/')[2] }}",
                ts="{{ dag_run.start_date | ts }}",
                source_bucket=config["bucket"],
                destination_bucket=os.environ.get("CALITP_BUCKET__LITTLEPAY_RAW_V3"),
                map_index_template="{{ basename(task.source_path) }}",
                destination_search_prefix="{{ task.entity }}/instance={{ task.provider }}/filename={{ basename(task.source_path) }}",
                destination_search_glob="**/{{ basename(task.source_path) }}",
                destination_path="{{ task.entity }}/instance={{ task.provider }}/filename={{ basename(task.source_path) }}/ts={{ task.ts }}/{{ basename(task.source_path) }}",
                report_path="raw_littlepay_sync_job_result/instance={{ task.provider }}/ts={{ task.ts }}/results_{{ splitext(basename(task.source_path))[0] }}.jsonl",
                pool="littlepay_download_pool",
            ).expand(source_path=files_to_copy)

            parsed_files = LittlepayPSVToJSONLOperator.partial(
                task_id=f"{provider}_littlepay_parse",
                retries=1,
                retry_delay=timedelta(seconds=10),
                source_bucket=os.environ.get("CALITP_BUCKET__LITTLEPAY_RAW_V3"),
                destination_bucket=os.environ.get("CALITP_BUCKET__LITTLEPAY_PARSED_V3"),
                trigger_rule=TriggerRule.ALL_DONE,
                map_index_template="{{ task.filename }}",
                destination_path="{{ task.entity }}/instance={{ task.provider }}/extract_filename={{ task.filename }}/ts={{ task.ts }}/{{ splitext(task.filename)[0] }}.jsonl.gz",
                report_path="littlepay_parse_job_results/instance={{ task.provider }}/ts={{ task.ts }}/results_{{ splitext(task.filename)[0] }}.jsonl",
                pool="littlepay_parse_pool",
            ).expand_kwargs(synced_files.output.map(parse_kwargs))

            (source_paths >> files_to_copy >> synced_files >> parsed_files)

        provider_groups.append(provider_group())

    latest_only >> provider_groups


download_and_parse_littlepay()
