import os
from datetime import datetime

from operators.littlepay_csv_to_jsonl_operator import LittlepayCSVToJSONLOperator
from operators.littlepay_s3_to_gcs_operator import LittlepayS3ToGCSOperator

from airflow import DAG, XComArg
from airflow.contrib.operators.s3_list_operator import S3ListOperator
from airflow.operators.latest_only import LatestOnlyOperator

LITTLEPAY_TRANSIT_PROVIDER_BUCKETS = {
    "atn": "littlepay-datafeed-prod-atn-5c319c40",
}


with DAG(
    dag_id="download_and_parse_littlepay",
    # Every day at midnight
    schedule="0 0 * * *",
    start_date=datetime(2025, 11, 1),
    catchup=False,
    tags=["payments", "littlepay"],
):
    latest_only = LatestOnlyOperator(task_id="latest_only", depends_on_past=False)

    for provider, bucket in LITTLEPAY_TRANSIT_PROVIDER_BUCKETS.items():
        littlepay_files = S3ListOperator(
            task_id="littlepay_list",
            bucket=bucket,
            aws_conn_id=f"aws_{provider}",
        )

        def sync_littlepay_kwargs(source_path):
            filename = os.path.basename(source_path)
            filetype = os.path.basename(os.path.dirname(source_path))
            return {
                "source_path": source_path,
                "destination_path": os.path.join(
                    filetype,
                    f"instance={provider}",
                    f"filename={filename}",
                    "ts={{ ts }}",
                    filename,
                ),
                "report_path": os.path.join(
                    "raw_littlepay_sync_job_result" f"instance={provider}",
                    "ts={{ ts }}",
                    f"results_{filename}.jsonl",
                ),
            }

        sync_littlepay = LittlepayS3ToGCSOperator.partial(
            aws_conn_id=f"aws_{provider}",
            source_bucket=bucket,
            destination_bucket=os.environ.get("CALITP_BUCKET__LITTLEPAY_RAW_V3"),
        ).expand_kwargs(XComArg(littlepay_files).map(sync_littlepay_kwargs))

        def parse_littlepay_kwargs(source_file):
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

        parse_littlepay = LittlepayCSVToJSONLOperator(
            source_bucket=os.environ.get("CALITP_BUCKET__LITTLEPAY_RAW_V3"),
            destination_bucket=os.environ.get("CALITP_BUCKET__LITTLEPAY_PARSED_V3"),
        ).expand_kwargs(XComArg(sync_littlepay).map(parse_littlepay_kwargs))

        sync_littlepay >> parse_littlepay
