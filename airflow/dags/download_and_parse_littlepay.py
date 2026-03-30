import os
from datetime import datetime

from dags import log_failure_to_slack
from operators.littlepay_psv_to_jsonl_operator import LittlepayPSVToJSONLOperator
from operators.littlepay_s3_to_gcs_operator import LittlepayS3ToGCSOperator

from airflow.decorators import dag, task, task_group
from airflow.operators.latest_only import LatestOnlyOperator
from airflow.providers.amazon.aws.operators.s3 import S3ListOperator
from airflow.utils.trigger_rule import TriggerRule

LITTLEPAY_TRANSIT_PROVIDER_BUCKETS = {
    "atn": "littlepay-datafeed-prod-atn-5c319c40",
    "ccjpa": "littlepay-datafeed-prod-ccjpa-5ca349d0",
    "clean-air-express": "littlepay-datafeed-prod-cal-itp-5b3f9b20",
    "eldorado-transit": "littlepay-datafeed-prod-eldorado-transit-fae490a0",
    "humboldt-transit-authority": "littlepay-datafeed-prod-humboldt-transit-aut-5c476e30",
    "lake-transit-authority": "littlepay-datafeed-prod-lake-transit-authori-5cb54b30",
    "mendocino-transit-authority": "littlepay-datafeed-prod-mendocino-transit-au-596cfe00",
    "mst": "littlepay-datafeed-prod-mst-5aa508d0",
    "nevada-county-connects": "littlepay-datafeed-prod-nevada-county-connec-7c9479e0",
    "redwood-coast-transit": "littlepay-datafeed-prod-redwood-coast-transi-5c4dfde0",
    "sacrt": "littlepay-datafeed-prod-sacrt-56af2970",
    "sbmtd": "littlepay-datafeed-prod-sbmtd-58599230",
    "slo-transit": "littlepay-datafeed-prod-slo-transit-979e5390",
    "slorta": "littlepay-datafeed-prod-slorta-991b7db0",
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
)
def download_and_parse_littlepay():
    latest_only = LatestOnlyOperator(task_id="latest_only", depends_on_past=False)

    @task
    def create_sync_kwargs(source_path: str, entity: str, provider: str):
        filename = os.path.basename(source_path)
        return {
            "source_path": source_path,
            "destination_search_prefix": os.path.join(
                entity,
                f"instance={provider}",
                f"filename={filename}",
            ),
            "destination_search_glob": os.path.join(
                "**",
                filename,
            ),
            "destination_path": os.path.join(
                entity,
                f"instance={provider}",
                f"filename={filename}",
                "ts={{ ts }}",
                filename,
            ),
            "report_path": os.path.join(
                "raw_littlepay_sync_job_result",
                f"instance={provider}",
                "ts={{ ts }}",
                f"results_{filename}.jsonl",
            ),
        }

    @task
    def create_parse_kwargs(source_file: dict, provider: str):
        return {
            "source_path": os.path.join(
                source_file["filetype"],
                f"instance={provider}",
                f"filename={source_file['filename']}",
                "ts={{ ts }}",
                source_file["filename"],
            ),
            "destination_path": os.path.join(
                source_file["filetype"],
                f"instance={provider}",
                f"extract_filename={source_file['filename']}",
                "ts={{ ts }}",
                f"{os.path.splitext(source_file['filename'])[0]}.jsonl.gz",
            ),
        }

    provider_groups = []
    for provider, bucket in LITTLEPAY_TRANSIT_PROVIDER_BUCKETS.items():

        @task_group(group_id=provider)
        def provider_group():
            for entity in LITTLEPAY_ENTITIES:

                @task_group(group_id=entity)
                def entity_group():
                    source_paths = S3ListOperator(
                        task_id="littlepay_list",
                        prefix=os.path.join(provider, "v3", entity),
                        bucket=bucket,
                        aws_conn_id=f"aws_{provider}",
                    )

                    sync_kwargs = create_sync_kwargs.partial(
                        provider=provider,
                        entity=entity,
                    ).expand(source_path=source_paths.output)

                    synced_files = LittlepayS3ToGCSOperator.partial(
                        task_id="littlepay_copy",
                        aws_conn_id=f"aws_{provider}",
                        provider=provider,
                        ts="{{ ts }}",
                        source_bucket=bucket,
                        destination_bucket=os.environ.get(
                            "CALITP_BUCKET__LITTLEPAY_RAW_V3"
                        ),
                        map_index_template="{{ task.source_path.split('/')[-1] }}",
                    ).expand_kwargs(sync_kwargs)

                    parse_kwargs = create_parse_kwargs.partial(
                        provider=provider,
                    ).expand(source_file=synced_files.output)

                    parsed_files = LittlepayPSVToJSONLOperator.partial(
                        task_id="littlepay_parse",
                        source_bucket=os.environ.get("CALITP_BUCKET__LITTLEPAY_RAW_V3"),
                        destination_bucket=os.environ.get(
                            "CALITP_BUCKET__LITTLEPAY_PARSED_V3"
                        ),
                        trigger_rule=TriggerRule.ALL_DONE,
                        map_index_template="{{ task.source_path.split('/')[-1] }}",
                    ).expand_kwargs(parse_kwargs)

                    (
                        source_paths
                        >> sync_kwargs
                        >> synced_files
                        >> parse_kwargs
                        >> parsed_files
                    )

                entity_group()

        provider_groups.append(provider_group())
    latest_only >> provider_groups


download_and_parse_littlepay()
