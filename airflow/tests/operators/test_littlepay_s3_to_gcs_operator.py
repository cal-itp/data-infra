import csv
import json
import os
from datetime import datetime, timedelta, timezone
from io import StringIO

import pytest
from dateutil.relativedelta import relativedelta
from moto import mock_aws
from operators.littlepay_s3_to_gcs_operator import LittlepayS3ToGCSOperator

from airflow.models.dag import DAG
from airflow.models.taskinstance import TaskInstance
from airflow.providers.amazon.aws.hooks.s3 import S3Hook
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class TestLittlepayS3ToGCSOperator:
    @pytest.fixture
    def execution_date(self) -> datetime:
        return datetime.fromisoformat("2025-06-01").replace(tzinfo=timezone.utc)

    @pytest.fixture
    def gcs_hook(self) -> GCSHook:
        return GCSHook()

    @pytest.fixture
    def s3_hook(self) -> S3Hook:
        return S3Hook()

    @pytest.fixture
    def test_dag(self, execution_date: datetime) -> DAG:
        return DAG(
            "test_dag",
            default_args={
                "owner": "airflow",
                "start_date": execution_date,
                "end_date": execution_date + relativedelta(months=+1),
            },
            schedule=relativedelta(months=+1),
        )

    @pytest.fixture
    def operator(
        self, execution_date: datetime, test_dag: DAG
    ) -> LittlepayS3ToGCSOperator:
        return LittlepayS3ToGCSOperator(
            dag=test_dag,
            task_id="littlepay_s3_to_gcs",
            ts=execution_date.isoformat(),
            provider="atn",
            aws_conn_id="aws_default",
            gcp_conn_id="google_cloud_default",
            source_bucket="mock-littlepay-bucket",
            source_path="atn/v3/authorisations/202510241114_authorisations.psv",
            destination_bucket=os.environ.get("CALITP_BUCKET__LITTLEPAY_RAW_V3"),
            destination_path="authorisations/instance=atn/filename=202510241114_authorisations.psv/ts=2025-06-01T00:00:00+00:00/202510241114_authorisations.psv",
            destination_search_prefix="authorisations/instance=atn/filename=202510241114_authorisations.psv",
            destination_search_glob="**/202510241114_authorisations.psv",
            report_path="raw_littlepay_sync_job_result/instance=atn/ts=2025-06-01T00:00:00+00:00/202510241114_authorisations.jsonl",
        )

    @mock_aws
    @pytest.mark.vcr
    def test_execute(
        self,
        test_dag: DAG,
        operator: LittlepayS3ToGCSOperator,
        execution_date: datetime,
        gcs_hook: GCSHook,
        s3_hook: S3Hook,
    ):
        # if gcs_hook.exists(
        #     bucket_name=os.environ.get("CALITP_BUCKET__LITTLEPAY_RAW_V3").replace(
        #         "gs://", ""
        #     ),
        #     object_name="raw_littlepay_sync_job_result/instance=atn/ts=2025-06-01T00:00:00+00:00/202510241114_authorisations.jsonl"
        # ):
        #     gcs_hook.delete(
        #         bucket_name=os.environ.get("CALITP_BUCKET__LITTLEPAY_RAW_V3").replace(
        #             "gs://", ""
        #         ),
        #         object_name="raw_littlepay_sync_job_result/instance=atn/ts=2025-06-01T00:00:00+00:00/202510241114_authorisations.jsonl"
        #     )
        old_files = gcs_hook.list(
            bucket_name=os.environ.get("CALITP_BUCKET__LITTLEPAY_RAW_V3").replace(
                "gs://", ""
            ),
            prefix="authorisations/instance=atn/filename=202510241114_authorisations.psv",
            match_glob="**/202510241114_authorisations.psv",
        )
        for file in old_files:
            gcs_hook.delete(
                bucket_name=os.environ.get("CALITP_BUCKET__LITTLEPAY_RAW_V3").replace(
                    "gs://", ""
                ),
                object_name=file,
            )
        s3_hook.create_bucket("mock-littlepay-bucket")
        fixture_path = os.path.normpath(
            os.path.join(
                os.path.dirname(os.path.realpath(__file__)),
                "../fixtures/littlepay-stub.psv",
            )
        )
        s3_hook.load_file(
            filename=fixture_path,
            key="atn/v3/authorisations/202510241114_authorisations.psv",
            bucket_name="mock-littlepay-bucket",
        )

        operator.run(
            start_date=execution_date,
            end_date=execution_date + timedelta(days=1),
            ignore_first_depends_on_past=True,
        )

        task = test_dag.get_task("littlepay_s3_to_gcs")
        task_instance = TaskInstance(task, execution_date=execution_date)
        xcom_value = task_instance.xcom_pull()
        assert xcom_value == {
            "filename": "202510241114_authorisations.psv",
            "filetype": "authorisations",
            "destination_path": os.path.join(
                "authorisations",
                "instance=atn",
                "filename=202510241114_authorisations.psv",
                "ts=2025-06-01T00:00:00+00:00",
                "202510241114_authorisations.psv",
            ),
            "report_path": os.path.join(
                "raw_littlepay_sync_job_result",
                "instance=atn",
                "ts=2025-06-01T00:00:00+00:00",
                "202510241114_authorisations.jsonl",
            ),
        }

        psv_result = gcs_hook.download(
            bucket_name=os.environ.get("CALITP_BUCKET__LITTLEPAY_RAW_V3").replace(
                "gs://", ""
            ),
            object_name=xcom_value["destination_path"],
        )
        reader = csv.DictReader(
            StringIO(psv_result.decode("utf-8-sig")),
            restkey="calitp_unknown_fields",
            delimiter="|",
        )
        result = list(reader)
        assert result[0] == {
            "acquirer_code": "CS",
            "aggregation_id": "abc123",
            "amount": "0.00",
            "authorisation_timestamp_utc": "2025-10-24T00:00:00.000Z",
            "channel": "TRANSIT",
            "currency_code": "840",
            "external_reference_number": "",
            "littlepay_reference_number": "",
            "participant_id": "atn",
            "record_updated_timestamp_utc": "2025-10-24T00:00:00.000Z",
            "request_created_timestamp_utc": "2025-10-24T00:00:00.000Z",
            "request_type": "CARD_CHECK",
            "response_code": "100",
            "retrieval_reference_number": "1234567890123456789012",
            "status": "VERIFIED",
        }

        metadata = gcs_hook.get_metadata(
            bucket_name=os.environ.get("CALITP_BUCKET__LITTLEPAY_RAW_V3").replace(
                "gs://", ""
            ),
            object_name=xcom_value["destination_path"],
        )
        parsed_metadata = json.loads(metadata["PARTITIONED_ARTIFACT_METADATA"])
        assert parsed_metadata == {
            "filename": "202510241114_authorisations.psv",
            "instance": "atn",
            "s3bucket": "mock-littlepay-bucket",
            "s3object": {
                "ETag": "5d46e84b9c9fa3cc87e4916c452c4de8",
                "Key": "atn/v3/authorisations/202510241114_authorisations.psv",
                "LastModified": parsed_metadata["s3object"]["LastModified"],
                "Size": 429,
                "StorageClass": None,
            },
            "ts": "2025-06-01T00:00:00+00:00",
        }

        report = gcs_hook.download(
            bucket_name=os.environ.get("CALITP_BUCKET__LITTLEPAY_RAW_V3").replace(
                "gs://", ""
            ),
            object_name=xcom_value["report_path"],
        )
        parsed_report = [json.loads(x) for x in report.splitlines()]
        assert parsed_report[0] == {
            "success": True,
            "prior": {},
            "exception": None,
            "extract": {
                "filename": "202510241114_authorisations.psv",
                "instance": "atn",
                "s3bucket": "mock-littlepay-bucket",
                "s3object": {
                    "ETag": "5d46e84b9c9fa3cc87e4916c452c4de8",
                    "Key": "atn/v3/authorisations/202510241114_authorisations.psv",
                    "LastModified": parsed_report[0]["extract"]["s3object"][
                        "LastModified"
                    ],
                    "Size": 429,
                    "StorageClass": None,
                },
                "ts": "2025-06-01T00:00:00+00:00",
            },
        }

        report_metadata = gcs_hook.get_metadata(
            bucket_name=os.environ.get("CALITP_BUCKET__LITTLEPAY_RAW_V3").replace(
                "gs://", ""
            ),
            object_name=xcom_value["report_path"],
        )
        parsed_report_metadata = json.loads(
            report_metadata["PARTITIONED_ARTIFACT_METADATA"]
        )
        assert parsed_report_metadata == {
            "ts": "2025-06-01T00:00:00+00:00",
            "filename": "results_202510241114_authorisations.psv.jsonl",
            "instance": "atn",
        }

    @pytest.fixture
    def file_exists_operator(
        self, execution_date: datetime, test_dag: DAG
    ) -> LittlepayS3ToGCSOperator:
        return LittlepayS3ToGCSOperator(
            dag=test_dag,
            task_id="file_exists_littlepay_s3_to_gcs",
            ts=execution_date.isoformat(),
            provider="atn",
            aws_conn_id="aws_default",
            gcp_conn_id="google_cloud_default",
            source_bucket="mock-littlepay-bucket",
            source_path="atn/v3/authorisations/202504291119_authorisations.psv",
            destination_bucket=os.environ.get("CALITP_BUCKET__LITTLEPAY_RAW_V3"),
            destination_path="authorisations/instance=atn/filename=202504291119_authorisations.psv/ts=2025-06-01T00:00:00+00:00/202504291119_authorisations.psv",
            destination_search_prefix="authorisations/instance=atn/filename=202504291119_authorisations.psv",
            destination_search_glob="**/202504291119_authorisations.psv",
            report_path="raw_littlepay_sync_job_result/instance=atn/ts=2025-06-01T00:00:00+00:00/202504291119_authorisations.jsonl",
        )

    @mock_aws
    @pytest.mark.freeze_time("2026-03-27 19:19:02+00:0")
    @pytest.mark.vcr
    def test_execute_file_exists(
        self,
        test_dag: DAG,
        file_exists_operator: LittlepayS3ToGCSOperator,
        execution_date: datetime,
        gcs_hook: GCSHook,
        s3_hook: S3Hook,
    ):
        s3_hook.create_bucket("mock-littlepay-bucket")
        fixture_path = os.path.normpath(
            os.path.join(
                os.path.dirname(os.path.realpath(__file__)),
                "../fixtures/littlepay-stub.psv",
            )
        )
        s3_hook.load_file(
            filename=fixture_path,
            key="atn/v3/authorisations/202504291119_authorisations.psv",
            bucket_name="mock-littlepay-bucket",
        )

        file_exists_operator.run(
            start_date=execution_date,
            end_date=execution_date + timedelta(days=1),
            ignore_first_depends_on_past=True,
        )

        task = test_dag.get_task("file_exists_littlepay_s3_to_gcs")
        task_instance = TaskInstance(task, execution_date=execution_date)
        xcom_value = task_instance.xcom_pull()
        assert xcom_value is None

    @pytest.fixture
    def old_file_exists_operator(
        self, execution_date: datetime, test_dag: DAG
    ) -> LittlepayS3ToGCSOperator:
        return LittlepayS3ToGCSOperator(
            dag=test_dag,
            task_id="old_file_exists_littlepay_s3_to_gcs",
            ts=execution_date.isoformat(),
            provider="atn",
            aws_conn_id="aws_default",
            gcp_conn_id="google_cloud_default",
            source_bucket="mock-littlepay-bucket",
            source_path="atn/v3/authorisations/202504291120_authorisations.psv",
            destination_bucket=os.environ.get("CALITP_BUCKET__LITTLEPAY_RAW_V3"),
            destination_path="authorisations/instance=atn/filename=202504291120_authorisations.psv/ts=2025-06-01T00:00:00+00:00/202504291120_authorisations.psv",
            destination_search_prefix="authorisations/instance=atn/filename=202504291120_authorisations.psv",
            destination_search_glob="**/202504291120_authorisations.psv",
            report_path="raw_littlepay_sync_job_result/instance=atn/ts=2025-06-01T00:00:00+00:00/202504291120_authorisations.jsonl",
        )

    @mock_aws
    @pytest.mark.freeze_time("2026-03-27 19:19:02+00:0")
    @pytest.mark.vcr
    def test_execute_old_file_exists(
        self,
        test_dag: DAG,
        old_file_exists_operator: LittlepayS3ToGCSOperator,
        execution_date: datetime,
        gcs_hook: GCSHook,
        s3_hook: S3Hook,
    ):
        s3_hook.create_bucket("mock-littlepay-bucket")
        fixture_path = os.path.normpath(
            os.path.join(
                os.path.dirname(os.path.realpath(__file__)),
                "../fixtures/littlepay-stub.psv",
            )
        )
        s3_hook.load_file(
            filename=fixture_path,
            key="atn/v3/authorisations/202504291120_authorisations.psv",
            bucket_name="mock-littlepay-bucket",
        )

        with open(fixture_path, "r") as f:
            content = f.read()

        gcs_hook.upload(
            bucket_name=os.environ.get("CALITP_BUCKET__LITTLEPAY_RAW_V3").replace(
                "gs://", ""
            ),
            object_name="authorisations/instance=atn/filename=202504291120_authorisations.psv/ts=2025-06-01T00:00:00+00:00/202504291120_authorisations.psv",
            # data="participant_id|aggregation_id|acquirer_code|request_type|amount|currency_code|retrieval_reference_number|littlepay_reference_number|external_reference_number|response_code|status|authorisation_timestamp_utc|record_updated_timestamp_utc|request_created_timestamp_utc|channel",
            data=content,
            mime_type="binary/octet-stream",
            gzip=False,
            metadata={
                "PARTITIONED_ARTIFACT_METADATA": {
                    "filename": "202504291120_authorisations.psv",
                    "instance": "atn",
                    "ts": "2025-06-01T00:00:00+00:00",
                    "s3bucket": "mock-littlepay-bucket",
                    "s3object": {
                        "Key": "atn/v3/authorisations/202504291120_authorisations.psv",
                        "LastModified": "2026-03-26 19:19:02+00:00",
                        "ETag": "5d46e84b9c9fa3cc87e4916c452c4de8",
                        "Size": 429,
                        "StorageClass": None,
                    },
                }
            },
        )

        old_file_exists_operator.run(
            start_date=execution_date,
            end_date=execution_date + timedelta(days=1),
            ignore_first_depends_on_past=True,
        )

        task = test_dag.get_task("old_file_exists_littlepay_s3_to_gcs")
        task_instance = TaskInstance(task, execution_date=execution_date)
        xcom_value = task_instance.xcom_pull()
        assert xcom_value == {
            "filename": "202504291120_authorisations.psv",
            "filetype": "authorisations",
            "destination_path": os.path.join(
                "authorisations",
                "instance=atn",
                "filename=202504291120_authorisations.psv",
                "ts=2025-06-01T00:00:00+00:00",
                "202504291120_authorisations.psv",
            ),
            "report_path": os.path.join(
                "raw_littlepay_sync_job_result",
                "instance=atn",
                "ts=2025-06-01T00:00:00+00:00",
                "202504291120_authorisations.jsonl",
            ),
        }

        psv_result = gcs_hook.download(
            bucket_name=os.environ.get("CALITP_BUCKET__LITTLEPAY_RAW_V3").replace(
                "gs://", ""
            ),
            object_name=xcom_value["destination_path"],
        )
        reader = csv.DictReader(
            StringIO(psv_result.decode("utf-8-sig")),
            restkey="calitp_unknown_fields",
            delimiter="|",
        )
        result = list(reader)
        assert result[0] == {
            "acquirer_code": "CS",
            "aggregation_id": "abc123",
            "amount": "0.00",
            "authorisation_timestamp_utc": "2025-10-24T00:00:00.000Z",
            "channel": "TRANSIT",
            "currency_code": "840",
            "external_reference_number": "",
            "littlepay_reference_number": "",
            "participant_id": "atn",
            "record_updated_timestamp_utc": "2025-10-24T00:00:00.000Z",
            "request_created_timestamp_utc": "2025-10-24T00:00:00.000Z",
            "request_type": "CARD_CHECK",
            "response_code": "100",
            "retrieval_reference_number": "1234567890123456789012",
            "status": "VERIFIED",
        }

        metadata = gcs_hook.get_metadata(
            bucket_name=os.environ.get("CALITP_BUCKET__LITTLEPAY_RAW_V3").replace(
                "gs://", ""
            ),
            object_name=xcom_value["destination_path"],
        )
        parsed_metadata = json.loads(metadata["PARTITIONED_ARTIFACT_METADATA"])
        assert parsed_metadata == {
            "filename": "202504291120_authorisations.psv",
            "instance": "atn",
            "s3bucket": "mock-littlepay-bucket",
            "s3object": {
                "ETag": "5d46e84b9c9fa3cc87e4916c452c4de8",
                "Key": "atn/v3/authorisations/202504291120_authorisations.psv",
                "LastModified": parsed_metadata["s3object"]["LastModified"],
                "Size": 429,
                "StorageClass": None,
            },
            "ts": "2025-06-01T00:00:00+00:00",
        }

        report = gcs_hook.download(
            bucket_name=os.environ.get("CALITP_BUCKET__LITTLEPAY_RAW_V3").replace(
                "gs://", ""
            ),
            object_name=xcom_value["report_path"],
        )
        parsed_report = [json.loads(x) for x in report.splitlines()]
        assert parsed_report[0] == {
            "success": True,
            "prior": {
                "ETag": "5d46e84b9c9fa3cc87e4916c452c4de8",
                "Key": "atn/v3/authorisations/202504291120_authorisations.psv",
                "LastModified": "2026-03-27 19:19:02+00:00",
                "Size": 429,
                "StorageClass": None,
            },
            "exception": None,
            "extract": {
                "filename": "202504291120_authorisations.psv",
                "instance": "atn",
                "s3bucket": "mock-littlepay-bucket",
                "s3object": {
                    "ETag": "5d46e84b9c9fa3cc87e4916c452c4de8",
                    "Key": "atn/v3/authorisations/202504291120_authorisations.psv",
                    "LastModified": parsed_report[0]["extract"]["s3object"][
                        "LastModified"
                    ],
                    "Size": 429,
                    "StorageClass": None,
                },
                "ts": "2025-06-01T00:00:00+00:00",
            },
        }

        report_metadata = gcs_hook.get_metadata(
            bucket_name=os.environ.get("CALITP_BUCKET__LITTLEPAY_RAW_V3").replace(
                "gs://", ""
            ),
            object_name=xcom_value["report_path"],
        )
        parsed_report_metadata = json.loads(
            report_metadata["PARTITIONED_ARTIFACT_METADATA"]
        )
        assert parsed_report_metadata == {
            "ts": "2025-06-01T00:00:00+00:00",
            "filename": "results_202504291120_authorisations.psv.jsonl",
            "instance": "atn",
        }
