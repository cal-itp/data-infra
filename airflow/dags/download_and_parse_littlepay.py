import os
from datetime import datetime, timedelta

from dags import log_failure_to_slack
from operators.littlepay_psv_to_jsonl_operator import LittlepayPSVToJSONLOperator
from operators.littlepay_s3_to_gcs_operator import LittlepayS3ToGCSOperator

from airflow.decorators import dag, task_group
from airflow.operators.latest_only import LatestOnlyOperator
from airflow.providers.amazon.aws.operators.s3 import S3ListOperator
from airflow.utils.trigger_rule import TriggerRule

LITTLEPAY_TRANSIT_PROVIDER_BUCKETS = {
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
    "sacrt": {
        "bucket": "littlepay-datafeed-prod-sacrt-56af2970",
        "prefix": "sacrt/v3",
    },
    "sbmtd": {
        "bucket": "littlepay-datafeed-prod-sbmtd-58599230",
        "prefix": "sbmtd/v3",
    },
    "slo-transit": {
        "bucket": "littlepay-datafeed-prod-slo-transit-979e5390",
        "prefix": "slo-transit/v3",
    },
    "slorta": {
        "bucket": "littlepay-datafeed-prod-slorta-991b7db0",
        "prefix": "slorta/v3",
    },
}

LITTLEPAY_ENTITIES = [
    "authorisations",
    "customer-funding-sources",
    "device-transaction-purchases",
    "device-transactions",
    "micropayment-adjustments",
    "micropayment-device-transactions",
    "micropayments",
    "products",
    "refunds",
    "settlements",
    "terminal-device-transactions",
]


@dag(
    # Every day at midnight
    schedule="0 0 * * *",
    start_date=datetime(2026, 3, 1),
    catchup=False,
    tags=["payments", "littlepay"],
    default_args={
        "email": os.getenv("CALITP_NOTIFY_EMAIL"),
        "email_on_failure": True,
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
    for provider, config in LITTLEPAY_TRANSIT_PROVIDER_BUCKETS.items():

        @task_group(group_id=provider)
        def provider_group():
            for entity in LITTLEPAY_ENTITIES:
                source_paths = S3ListOperator(
                    task_id="littlepay_list",
                    retries=1,
                    retry_delay=timedelta(seconds=10),
                    prefix=os.path.join(config["prefix"], entity),
                    bucket=config["bucket"],
                    aws_conn_id=f"aws_{provider}",
                )

                synced_files = LittlepayS3ToGCSOperator.partial(
                    task_id="littlepay_copy",
                    retries=1,
                    retry_delay=timedelta(seconds=10),
                    provider=provider,
                    aws_conn_id=f"aws_{provider}",
                    entity=entity,
                    ts="{{ dag_run.start_date | ts }}",
                    source_bucket=config["bucket"],
                    destination_bucket=os.environ.get(
                        "CALITP_BUCKET__LITTLEPAY_RAW_V3"
                    ),
                    map_index_template="{{ basename(task.source_path) }}",
                    destination_search_prefix="{{ task.entity }}/instance={{ task.provider }}/filename={{ basename(task.source_path) }}",
                    destination_search_glob="**/{{ basename(task.source_path) }}",
                    destination_path="{{ task.entity }}/instance={{ task.provider }}/filename={{ basename(task.source_path) }}/ts={{ task.ts }}/{{ basename(task.source_path) }}",
                    report_path="raw_littlepay_sync_job_result/instance={{ task.provider }}/ts={{ task.ts }}/results_{{ basename(task.source_path) }}.jsonl",
                ).expand(source_path=source_paths.output)

                parsed_files = LittlepayPSVToJSONLOperator.partial(
                    task_id="littlepay_parse",
                    retries=1,
                    retry_delay=timedelta(seconds=10),
                    source_bucket=os.environ.get("CALITP_BUCKET__LITTLEPAY_RAW_V3"),
                    destination_bucket=os.environ.get(
                        "CALITP_BUCKET__LITTLEPAY_PARSED_V3"
                    ),
                    trigger_rule=TriggerRule.ALL_DONE,
                    map_index_template="{{ task.filename }}",
                    source_path="{{ task.entity }}/instance={{ task.provider }}/filename={{ task.filename }}/ts={{ task.ts }}/{{ task.filename }}",
                    destination_path="{{ task.entity }}/instance={{ task.provider }}/extract_filename={{ task.filename }}/ts={{ task.ts }}/{{ splitext(task.filename)[0] }}.jsonl.gz",
                ).expand_kwargs(
                    synced_files.output.map(
                        lambda file: {
                            "entity": file["entity"],
                            "provider": file["provider"],
                            "filename": file["filename"],
                            "ts": file["ts"],
                        }
                    )
                )

                (source_paths >> synced_files >> parsed_files)

        provider_groups.append(provider_group())

    latest_only >> provider_groups


download_and_parse_littlepay()
