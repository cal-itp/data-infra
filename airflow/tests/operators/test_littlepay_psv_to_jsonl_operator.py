import gzip
import json
import os
from datetime import datetime, timedelta, timezone

import pytest
from operators.littlepay_psv_to_jsonl_operator import LittlepayPSVToJSONLOperator

from airflow.models.dag import DAG
from airflow.models.taskinstance import TaskInstance
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class TestLittlepayPSVToJSONLOperator:
    @pytest.fixture
    def execution_date(self) -> datetime:
        return datetime.fromisoformat("2025-06-02").replace(tzinfo=timezone.utc)

    @pytest.fixture
    def gcs_hook(self) -> GCSHook:
        return GCSHook()

    @pytest.fixture
    def source_path(self) -> str:
        return "authorisations/instance=atn/filename=202510241114_authorisations.psv/ts=2025-06-01T00:00:00+00:00/202510241114_authorisations.psv"

    @pytest.fixture
    def destination_path(self) -> str:
        return "authorisations/instance=atn/extract_filename=202510241114_authorisations.psv/ts=2025-06-01T00:00:00+00:00/202510241114_authorisations.jsonl.gz"

    @pytest.fixture
    def report_path(self) -> str:
        return "littlepay_parse_job_results/instance=atn/ts=2025-06-01T00:00:00+00:00/202510241114_authorisations.jsonl"

    @pytest.fixture
    def test_dag(self, execution_date: datetime) -> DAG:
        return DAG(
            "test_dag",
            default_args={
                "owner": "airflow",
                "start_date": execution_date,
                "end_date": execution_date + timedelta(days=1),
            },
            schedule=timedelta(days=1),
        )

    @pytest.fixture
    def operator(
        self,
        test_dag: DAG,
        execution_date: datetime,
        destination_path: str,
        source_path: str,
        report_path: str,
    ) -> LittlepayPSVToJSONLOperator:
        return LittlepayPSVToJSONLOperator(
            task_id="littlepay_to_jsonl",
            gcp_conn_id="google_cloud_default",
            source_bucket=os.environ.get("CALITP_BUCKET__LITTLEPAY_RAW_V3"),
            source_path=source_path,
            destination_bucket=os.environ.get("CALITP_BUCKET__LITTLEPAY_PARSED_V3"),
            destination_path=destination_path,
            report_path=report_path,
            entity="authorisations",
            provider="atn",
            filename="202510241114_authorisations.psv",
            ts="2025-06-01T00:00:00+00:00",
            dag=test_dag,
        )

    @pytest.mark.vcr
    def test_execute(
        self,
        test_dag: DAG,
        operator: LittlepayPSVToJSONLOperator,
        execution_date: datetime,
        gcs_hook: GCSHook,
        destination_path: str,
        report_path: str,
    ):
        operator.run(
            start_date=execution_date,
            end_date=execution_date + timedelta(days=1),
            ignore_first_depends_on_past=True,
        )

        task = test_dag.get_task("littlepay_to_jsonl")
        task_instance = TaskInstance(task, execution_date=execution_date)
        xcom_value = task_instance.xcom_pull()
        assert xcom_value == {
            "destination_path": os.path.join(
                "authorisations",
                "instance=atn",
                "extract_filename=202510241114_authorisations.psv",
                "ts=2025-06-01T00:00:00+00:00",
                "202510241114_authorisations.jsonl.gz",
            ),
        }

        compressed_result = gcs_hook.download(
            bucket_name=os.environ.get("CALITP_BUCKET__LITTLEPAY_PARSED_V3").replace(
                "gs://", ""
            ),
            object_name=destination_path,
        )
        decompressed_result = gzip.decompress(compressed_result)
        result = [json.loads(x) for x in decompressed_result.splitlines()]
        assert result[0] == {
            "_line_number": 1,
            "acquirer_code": "CS",
            "aggregation_id": "abc123",
            "amount": "0.00",
            "authorisation_timestamp_utc": "2025-10-24T00:00:00.000Z",
            "channel": "TRANSIT",
            "currency_code": "840",
            "participant_id": "atn",
            "record_updated_timestamp_utc": "2025-10-24T00:00:00.000Z",
            "request_created_timestamp_utc": "2025-10-24T00:00:00.000Z",
            "request_type": "CARD_CHECK",
            "response_code": "100",
            "retrieval_reference_number": "1234567890123456789012",
            "status": "VERIFIED",
        }

        metadata = gcs_hook.get_metadata(
            bucket_name=os.environ.get("CALITP_BUCKET__LITTLEPAY_PARSED_V3").replace(
                "gs://", ""
            ),
            object_name=destination_path,
        )
        parsed_metadata = json.loads(metadata["PARTITIONED_ARTIFACT_METADATA"])
        assert parsed_metadata == {
            "filename": "202510241114_authorisations.jsonl.gz",
            "extract": {
                "filename": "202510241114_authorisations.psv",
                "instance": "atn",
                "s3bucket": "mock-littlepay-bucket",
                "s3object": {
                    "Key": "atn/v3/authorisations/202510241114_authorisations.psv",
                    "LastModified": parsed_metadata["extract"]["s3object"][
                        "LastModified"
                    ],
                    "ETag": "5d46e84b9c9fa3cc87e4916c452c4de8",
                    "Size": 429,
                    "StorageClass": None,
                },
                "ts": "2025-06-01T00:00:00+00:00",
            },
        }

        report = gcs_hook.download(
            bucket_name=os.environ.get("CALITP_BUCKET__LITTLEPAY_PARSED_V3").replace(
                "gs://", ""
            ),
            object_name=report_path,
        )
        parsed_report = [json.loads(x) for x in report.splitlines()]
        assert parsed_report[0] == {
            "filename": "202510241114_authorisations.jsonl.gz",
            "extract": {
                "filename": "202510241114_authorisations.psv",
                "instance": "atn",
                "s3bucket": "mock-littlepay-bucket",
                "s3object": {
                    "Key": "atn/v3/authorisations/202510241114_authorisations.psv",
                    "LastModified": parsed_report[0]["extract"]["s3object"][
                        "LastModified"
                    ],
                    "ETag": "5d46e84b9c9fa3cc87e4916c452c4de8",
                    "Size": 429,
                    "StorageClass": None,
                },
                "ts": "2025-06-01T00:00:00+00:00",
            },
        }

        report_metadata = gcs_hook.get_metadata(
            bucket_name=os.environ.get("CALITP_BUCKET__LITTLEPAY_PARSED_V3").replace(
                "gs://", ""
            ),
            object_name=report_path,
        )
        parsed_report_metadata = json.loads(
            report_metadata["PARTITIONED_ARTIFACT_METADATA"]
        )
        assert parsed_report_metadata == {
            "ts": "2025-06-01T00:00:00+00:00",
            "filename": "results_202510241114_authorisations.psv.jsonl",
            "instance": "atn",
        }
