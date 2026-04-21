import csv
import json
import os
from datetime import datetime, timedelta, timezone
from io import StringIO

import pytest
from dateutil.relativedelta import relativedelta
from freezegun import freeze_time
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
    def source_path(self) -> str:
        return "atn/v3/authorisations/202510241114_authorisations.psv"

    @pytest.fixture
    def destination_path(self) -> str:
        return "authorisations/instance=atn/filename=202510241114_authorisations.psv/ts=2025-06-01T00:00:00+00:00/202510241114_authorisations.psv"

    @pytest.fixture
    def destination_search_prefix(self) -> str:
        return "authorisations/instance=atn/filename=202510241114_authorisations.psv"

    @pytest.fixture
    def destination_search_glob(self) -> str:
        return "**/202510241114_authorisations.psv"

    @pytest.fixture
    def report_path(self) -> str:
        return "raw_littlepay_sync_job_result/instance=atn/ts=2025-06-01T00:00:00+00:00/202510241114_authorisations.jsonl"

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
        self,
        execution_date: datetime,
        test_dag: DAG,
        source_path: str,
        destination_path: str,
        destination_search_prefix: str,
        destination_search_glob: str,
        report_path: str,
    ) -> LittlepayS3ToGCSOperator:
        return LittlepayS3ToGCSOperator(
            dag=test_dag,
            task_id="littlepay_s3_to_gcs",
            ts=execution_date.isoformat(),
            provider="atn",
            entity="authorisations",
            aws_conn_id="aws_default",
            gcp_conn_id="google_cloud_default",
            source_bucket="mock-littlepay-bucket",
            source_path=source_path,
            destination_bucket=os.environ.get("CALITP_BUCKET__LITTLEPAY_RAW_V3"),
            destination_path=destination_path,
            destination_search_prefix=destination_search_prefix,
            destination_search_glob=destination_search_glob,
            report_path=report_path,
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
        source_path: str,
        destination_search_prefix: str,
        destination_search_glob: str,
        destination_path: str,
        report_path: str,
    ):
        old_files = gcs_hook.list(
            bucket_name=os.environ.get("CALITP_BUCKET__LITTLEPAY_RAW_V3").replace(
                "gs://", ""
            ),
            prefix=destination_search_prefix,
            match_glob=destination_search_glob,
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
            key=source_path,
            bucket_name="mock-littlepay-bucket",
        )
        s3_file = s3_hook.get_key(
            bucket_name="mock-littlepay-bucket",
            key=source_path,
        ).get()

        operator.run(
            start_date=execution_date,
            end_date=execution_date + timedelta(days=1),
            ignore_first_depends_on_past=True,
        )

        task = test_dag.get_task("littlepay_s3_to_gcs")
        task_instance = TaskInstance(task, execution_date=execution_date)
        xcom_value = task_instance.xcom_pull()
        assert xcom_value == {
            "provider": "atn",
            "entity": "authorisations",
            "filename": "202510241114_authorisations.psv",
            "ts": "2025-06-01T00:00:00+00:00",
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
            object_name=destination_path,
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
            object_name=destination_path,
        )
        parsed_metadata = json.loads(metadata["PARTITIONED_ARTIFACT_METADATA"])
        assert parsed_metadata == {
            "filename": "202510241114_authorisations.psv",
            "instance": "atn",
            "s3bucket": "mock-littlepay-bucket",
            "s3object": {
                "Key": "atn/v3/authorisations/202510241114_authorisations.psv",
                "LastModified": parsed_metadata["s3object"]["LastModified"],
                "ETag": s3_file["ETag"],
                "Size": s3_file["ContentLength"],
                "StorageClass": None,
            },
            "ts": "2025-06-01T00:00:00+00:00",
        }

        report = gcs_hook.download(
            bucket_name=os.environ.get("CALITP_BUCKET__LITTLEPAY_RAW_V3").replace(
                "gs://", ""
            ),
            object_name=report_path,
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
                    "ETag": '"5d46e84b9c9fa3cc87e4916c452c4de8"',
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

    @pytest.fixture
    def file_exists_source_path(self) -> str:
        return "atn/v3/authorisations/202504291120_authorisations.psv"

    @pytest.fixture
    def file_exists_destination_path(self) -> str:
        return (
            "authorisations/instance=atn/filename=202504291120_authorisations.psv/ts=2025-06-01T00:00:00+00:00/202504291120_authorisations.psv",
        )

    @pytest.fixture
    def file_exists_path(self) -> str:
        return "authorisations/instance=atn/filename=202504291120_authorisations.psv/ts=2025-05-01T00:00:00+00:00/202504291120_authorisations.psv"

    @pytest.fixture
    def file_exists_destination_search_prefix(self) -> str:
        return "authorisations/instance=atn/filename=202504291120_authorisations.psv"

    @pytest.fixture
    def file_exists_destination_search_glob(self) -> str:
        return "**/202504291120_authorisations.psv"

    @pytest.fixture
    def file_exists_report_path(self) -> str:
        return "raw_littlepay_sync_job_result/instance=atn/ts=2025-06-01T00:00:00+00:00/202504291120_authorisations.jsonl"

    @pytest.fixture
    def file_exists_dag(self, execution_date: datetime) -> DAG:
        return DAG(
            "test_file_exists_dag",
            default_args={
                "owner": "airflow",
                "start_date": execution_date,
                "end_date": execution_date + relativedelta(months=+1),
            },
            schedule=relativedelta(months=+1),
        )

    @pytest.fixture
    def file_exists_operator(
        self,
        execution_date: datetime,
        file_exists_dag: DAG,
        file_exists_source_path: str,
        file_exists_destination_path: str,
        file_exists_destination_search_prefix: str,
        file_exists_destination_search_glob: str,
        file_exists_report_path: str,
    ) -> LittlepayS3ToGCSOperator:
        return LittlepayS3ToGCSOperator(
            dag=file_exists_dag,
            task_id="file_exists_littlepay_s3_to_gcs",
            ts=execution_date.isoformat(),
            provider="atn",
            entity="authorisations",
            aws_conn_id="aws_default",
            gcp_conn_id="google_cloud_default",
            source_bucket="mock-littlepay-bucket",
            source_path=file_exists_source_path,
            destination_bucket=os.environ.get("CALITP_BUCKET__LITTLEPAY_RAW_V3"),
            destination_path=file_exists_destination_path,
            destination_search_prefix=file_exists_destination_search_prefix,
            destination_search_glob=file_exists_destination_search_glob,
            report_path=file_exists_report_path,
        )

    @mock_aws
    @pytest.mark.vcr
    def test_execute_file_exists(
        self,
        file_exists_dag: DAG,
        file_exists_operator: LittlepayS3ToGCSOperator,
        execution_date: datetime,
        gcs_hook: GCSHook,
        s3_hook: S3Hook,
        file_exists_source_path: str,
        file_exists_path: str,
        capsys,
    ):
        with freeze_time("2026-03-01T00:00:00"):
            s3_hook.create_bucket("mock-littlepay-bucket")
            fixture_path = os.path.normpath(
                os.path.join(
                    os.path.dirname(os.path.realpath(__file__)),
                    "../fixtures/littlepay-stub.psv",
                )
            )
            s3_hook.load_file(
                filename=fixture_path,
                key=file_exists_source_path,
                bucket_name="mock-littlepay-bucket",
            )
            s3_file = s3_hook.get_key(
                bucket_name="mock-littlepay-bucket",
                key=file_exists_source_path,
            ).get()

        with open(fixture_path, "r") as fixture_file:
            gcs_hook.upload(
                bucket_name=os.environ.get("CALITP_BUCKET__LITTLEPAY_RAW_V3").replace(
                    "gs://", ""
                ),
                object_name=file_exists_path,
                data=fixture_file.read(),
                mime_type="binary/octet-stream",
                gzip=False,
                metadata={
                    "PARTITIONED_ARTIFACT_METADATA": json.dumps(
                        {
                            "filename": "202504291120_authorisations.psv",
                            "instance": "atn",
                            "ts": "2025-05-01T00:00:00+00:00",
                            "s3bucket": "mock-littlepay-bucket",
                            "s3object": {
                                "Key": file_exists_source_path,
                                "LastModified": s3_file["LastModified"].isoformat(),
                                "ETag": s3_file["ETag"],
                                "Size": s3_file["ContentLength"],
                                "StorageClass": None,
                            },
                        }
                    )
                },
            )

        file_exists_operator.run(
            start_date=execution_date,
            end_date=execution_date + timedelta(days=1),
            ignore_first_depends_on_past=True,
        )

        task = file_exists_dag.get_task("file_exists_littlepay_s3_to_gcs")
        task_instance = TaskInstance(task, execution_date=execution_date)
        xcom_value = task_instance.xcom_pull()
        assert xcom_value is None

        captured = capsys.readouterr()
        assert "INFO - File already downloaded." in captured.out

    @pytest.fixture
    def old_file_source_path(self) -> str:
        return "atn/v3/authorisations/202504300000_authorisations.psv"

    @pytest.fixture
    def old_file_destination_path(self) -> str:
        return "authorisations/instance=atn/filename=202504300000_authorisations.psv/ts=2025-06-01T00:00:00+00:00/202504300000_authorisations.psv"

    @pytest.fixture
    def old_file_path(self) -> str:
        return "authorisations/instance=atn/filename=202504300000_authorisations.psv/ts=2025-05-01T00:00:00+00:00/202504300000_authorisations.psv"

    @pytest.fixture
    def old_file_destination_search_prefix(self) -> str:
        return "authorisations/instance=atn/filename=202504300000_authorisations.psv"

    @pytest.fixture
    def old_file_destination_search_glob(self) -> str:
        return "**/202504300000_authorisations.psv"

    @pytest.fixture
    def old_file_report_path(self) -> str:
        return "raw_littlepay_sync_job_result/instance=atn/ts=2025-06-01T00:00:00+00:00/202504300000_authorisations.jsonl"

    @pytest.fixture
    def old_file_dag(self, execution_date: datetime) -> DAG:
        return DAG(
            "test_old_file_dag",
            default_args={
                "owner": "airflow",
                "start_date": execution_date,
                "end_date": execution_date + relativedelta(months=+1),
            },
            schedule=relativedelta(months=+1),
        )

    @pytest.fixture
    def old_file_operator(
        self,
        execution_date: datetime,
        old_file_dag: DAG,
        old_file_source_path: str,
        old_file_destination_path: str,
        old_file_destination_search_prefix: str,
        old_file_destination_search_glob: str,
        old_file_report_path: str,
    ) -> LittlepayS3ToGCSOperator:
        return LittlepayS3ToGCSOperator(
            dag=old_file_dag,
            task_id="old_file_littlepay_s3_to_gcs",
            ts=execution_date.isoformat(),
            provider="atn",
            entity="authorisations",
            aws_conn_id="aws_default",
            gcp_conn_id="google_cloud_default",
            source_bucket="mock-littlepay-bucket",
            source_path=old_file_source_path,
            destination_bucket=os.environ.get("CALITP_BUCKET__LITTLEPAY_RAW_V3"),
            destination_path=old_file_destination_path,
            destination_search_prefix=old_file_destination_search_prefix,
            destination_search_glob=old_file_destination_search_glob,
            report_path=old_file_report_path,
        )

    @mock_aws
    @pytest.mark.vcr
    def test_execute_old_file(
        self,
        old_file_dag: DAG,
        old_file_operator: LittlepayS3ToGCSOperator,
        execution_date: datetime,
        gcs_hook: GCSHook,
        s3_hook: S3Hook,
        old_file_source_path: str,
        old_file_path: str,
        old_file_destination_path: str,
        old_file_report_path: str,
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
            key=old_file_source_path,
            bucket_name="mock-littlepay-bucket",
        )
        s3_file = s3_hook.get_key(
            bucket_name="mock-littlepay-bucket",
            key=old_file_source_path,
        ).get()

        with open(fixture_path, "r") as fixture_file:
            gcs_hook.upload(
                bucket_name=os.environ.get("CALITP_BUCKET__LITTLEPAY_RAW_V3").replace(
                    "gs://", ""
                ),
                object_name=old_file_path,
                data=fixture_file.read(),
                mime_type="binary/octet-stream",
                gzip=False,
                metadata={
                    "PARTITIONED_ARTIFACT_METADATA": json.dumps(
                        {
                            "filename": "202504300000_authorisations.psv",
                            "instance": "atn",
                            "ts": "2025-05-01T00:00:00+00:00",
                            "s3bucket": "mock-littlepay-bucket",
                            "s3object": {
                                "Key": old_file_source_path,
                                "LastModified": "2025-05-01T00:00:00+00:00",
                                "ETag": s3_file["ETag"],
                                "Size": s3_file["ContentLength"],
                                "StorageClass": "STANDARD",
                            },
                        }
                    )
                },
            )

        old_file_operator.run(
            start_date=execution_date,
            end_date=execution_date + timedelta(days=1),
            ignore_first_depends_on_past=True,
        )

        task = old_file_dag.get_task("old_file_littlepay_s3_to_gcs")
        task_instance = TaskInstance(task, execution_date=execution_date)
        xcom_value = task_instance.xcom_pull()
        assert xcom_value == {
            "provider": "atn",
            "entity": "authorisations",
            "filename": "202504300000_authorisations.psv",
            "ts": "2025-06-01T00:00:00+00:00",
            "destination_path": os.path.join(
                "authorisations",
                "instance=atn",
                "filename=202504300000_authorisations.psv",
                "ts=2025-06-01T00:00:00+00:00",
                "202504300000_authorisations.psv",
            ),
            "report_path": os.path.join(
                "raw_littlepay_sync_job_result",
                "instance=atn",
                "ts=2025-06-01T00:00:00+00:00",
                "202504300000_authorisations.jsonl",
            ),
        }

        metadata = gcs_hook.get_metadata(
            bucket_name=os.environ.get("CALITP_BUCKET__LITTLEPAY_RAW_V3").replace(
                "gs://", ""
            ),
            object_name=old_file_destination_path,
        )
        parsed_metadata = json.loads(metadata["PARTITIONED_ARTIFACT_METADATA"])
        assert parsed_metadata == {
            "filename": "202504300000_authorisations.psv",
            "instance": "atn",
            "s3bucket": "mock-littlepay-bucket",
            "s3object": {
                "Key": "atn/v3/authorisations/202504300000_authorisations.psv",
                "LastModified": parsed_metadata["s3object"]["LastModified"],
                "ETag": s3_file["ETag"],
                "Size": s3_file["ContentLength"],
                "StorageClass": None,
            },
            "ts": "2025-06-01T00:00:00+00:00",
        }

        report = gcs_hook.download(
            bucket_name=os.environ.get("CALITP_BUCKET__LITTLEPAY_RAW_V3").replace(
                "gs://", ""
            ),
            object_name=old_file_report_path,
        )
        parsed_report = [json.loads(x) for x in report.splitlines()]
        assert parsed_report[0] == {
            "success": True,
            "prior": {
                "Key": "atn/v3/authorisations/202504300000_authorisations.psv",
                "LastModified": parsed_report[0]["prior"]["LastModified"],
                "ETag": s3_file["ETag"],
                "Size": s3_file["ContentLength"],
                "StorageClass": "STANDARD",
            },
            "exception": None,
            "extract": {
                "filename": "202504300000_authorisations.psv",
                "instance": "atn",
                "s3bucket": "mock-littlepay-bucket",
                "s3object": {
                    "Key": "atn/v3/authorisations/202504300000_authorisations.psv",
                    "LastModified": parsed_report[0]["extract"]["s3object"][
                        "LastModified"
                    ],
                    "ETag": s3_file["ETag"],
                    "Size": s3_file["ContentLength"],
                    "StorageClass": None,
                },
                "ts": "2025-06-01T00:00:00+00:00",
            },
        }

        report_metadata = gcs_hook.get_metadata(
            bucket_name=os.environ.get("CALITP_BUCKET__LITTLEPAY_RAW_V3").replace(
                "gs://", ""
            ),
            object_name=old_file_report_path,
        )
        parsed_report_metadata = json.loads(
            report_metadata["PARTITIONED_ARTIFACT_METADATA"]
        )
        assert parsed_report_metadata == {
            "ts": "2025-06-01T00:00:00+00:00",
            "filename": "results_202504300000_authorisations.psv.jsonl",
            "instance": "atn",
        }

    @pytest.fixture
    def invalid_entity_source_path(self) -> str:
        return "atn/v3/something/202504291120_something.psv"

    @pytest.fixture
    def invalid_entity_destination_path(self) -> str:
        return (
            "something/instance=atn/filename=202504291120_something.psv/ts=2025-06-01T00:00:00+00:00/202504291120_something.psv",
        )

    @pytest.fixture
    def invalid_entity_path(self) -> str:
        return "something/instance=atn/filename=202504291120_something.psv/ts=2025-05-01T00:00:00+00:00/202504291120_something.psv"

    @pytest.fixture
    def invalid_entity_destination_search_prefix(self) -> str:
        return "something/instance=atn/filename=202504291120_something.psv"

    @pytest.fixture
    def invalid_entity_destination_search_glob(self) -> str:
        return "**/202504291120_something.psv"

    @pytest.fixture
    def invalid_entity_report_path(self) -> str:
        return "raw_littlepay_sync_job_result/instance=atn/ts=2025-06-01T00:00:00+00:00/202504291120_something.jsonl"

    @pytest.fixture
    def invalid_entity_dag(self, execution_date: datetime) -> DAG:
        return DAG(
            "test_invalid_entity_dag",
            default_args={
                "owner": "airflow",
                "start_date": execution_date,
                "end_date": execution_date + relativedelta(months=+1),
            },
            schedule=relativedelta(months=+1),
        )

    @pytest.fixture
    def invalid_entity_operator(
        self,
        execution_date: datetime,
        invalid_entity_dag: DAG,
        invalid_entity_source_path: str,
        invalid_entity_destination_path: str,
        invalid_entity_destination_search_prefix: str,
        invalid_entity_destination_search_glob: str,
        invalid_entity_report_path: str,
    ) -> LittlepayS3ToGCSOperator:
        return LittlepayS3ToGCSOperator(
            dag=invalid_entity_dag,
            task_id="invalid_entity_littlepay_s3_to_gcs",
            ts=execution_date.isoformat(),
            provider="atn",
            entity="something",
            aws_conn_id="aws_default",
            gcp_conn_id="google_cloud_default",
            source_bucket="mock-littlepay-bucket",
            source_path=invalid_entity_source_path,
            destination_bucket=os.environ.get("CALITP_BUCKET__LITTLEPAY_RAW_V3"),
            destination_path=invalid_entity_destination_path,
            destination_search_prefix=invalid_entity_destination_search_prefix,
            destination_search_glob=invalid_entity_destination_search_glob,
            report_path=invalid_entity_report_path,
        )

    @mock_aws
    @pytest.mark.vcr
    def test_execute_invalid_entity(
        self,
        invalid_entity_dag: DAG,
        invalid_entity_operator: LittlepayS3ToGCSOperator,
        execution_date: datetime,
        gcs_hook: GCSHook,
        s3_hook: S3Hook,
        invalid_entity_source_path: str,
        invalid_entity_path: str,
        capsys,
    ):
        invalid_entity_operator.run(
            start_date=execution_date,
            end_date=execution_date + timedelta(days=1),
            ignore_first_depends_on_past=True,
        )

        task = invalid_entity_dag.get_task("invalid_entity_littlepay_s3_to_gcs")
        task_instance = TaskInstance(task, execution_date=execution_date)
        xcom_value = task_instance.xcom_pull()
        assert xcom_value is None

        captured = capsys.readouterr()
        assert "WARNING - Entity is not in the list." in captured.out

    @pytest.fixture
    def invalid_file_type_source_path(self) -> str:
        return "atn/v3/authorisations/202504291120_authorisations.txt"

    @pytest.fixture
    def invalid_file_type_destination_path(self) -> str:
        return (
            "authorisations/instance=atn/filename=202504291120_authorisations.txt/ts=2025-06-01T00:00:00+00:00/202504291120_authorisations.txt",
        )

    @pytest.fixture
    def invalid_file_type_path(self) -> str:
        return "authorisations/instance=atn/filename=202504291120_authorisations.txt/ts=2025-05-01T00:00:00+00:00/202504291120_authorisations.txt"

    @pytest.fixture
    def invalid_file_type_destination_search_prefix(self) -> str:
        return "authorisations/instance=atn/filename=202504291120_authorisations.txt"

    @pytest.fixture
    def invalid_file_type_destination_search_glob(self) -> str:
        return "**/202504291120_authorisations.txt"

    @pytest.fixture
    def invalid_file_type_report_path(self) -> str:
        return "raw_littlepay_sync_job_result/instance=atn/ts=2025-06-01T00:00:00+00:00/202504291120_authorisations.jsonl"

    @pytest.fixture
    def invalid_file_type_dag(self, execution_date: datetime) -> DAG:
        return DAG(
            "test_invalid_file_type_dag",
            default_args={
                "owner": "airflow",
                "start_date": execution_date,
                "end_date": execution_date + relativedelta(months=+1),
            },
            schedule=relativedelta(months=+1),
        )

    @pytest.fixture
    def invalid_file_type_operator(
        self,
        execution_date: datetime,
        invalid_file_type_dag: DAG,
        invalid_file_type_source_path: str,
        invalid_file_type_destination_path: str,
        invalid_file_type_destination_search_prefix: str,
        invalid_file_type_destination_search_glob: str,
        invalid_file_type_report_path: str,
    ) -> LittlepayS3ToGCSOperator:
        return LittlepayS3ToGCSOperator(
            dag=invalid_file_type_dag,
            task_id="invalid_file_type_littlepay_s3_to_gcs",
            ts=execution_date.isoformat(),
            provider="atn",
            entity="authorisations",
            aws_conn_id="aws_default",
            gcp_conn_id="google_cloud_default",
            source_bucket="mock-littlepay-bucket",
            source_path=invalid_file_type_source_path,
            destination_bucket=os.environ.get("CALITP_BUCKET__LITTLEPAY_RAW_V3"),
            destination_path=invalid_file_type_destination_path,
            destination_search_prefix=invalid_file_type_destination_search_prefix,
            destination_search_glob=invalid_file_type_destination_search_glob,
            report_path=invalid_file_type_report_path,
        )

    @mock_aws
    @pytest.mark.vcr
    def test_execute_invalid_file_type(
        self,
        invalid_file_type_dag: DAG,
        invalid_file_type_operator: LittlepayS3ToGCSOperator,
        execution_date: datetime,
        gcs_hook: GCSHook,
        s3_hook: S3Hook,
        invalid_file_type_source_path: str,
        invalid_file_type_path: str,
        capsys,
    ):
        invalid_file_type_operator.run(
            start_date=execution_date,
            end_date=execution_date + timedelta(days=1),
            ignore_first_depends_on_past=True,
        )

        task = invalid_file_type_dag.get_task("invalid_file_type_littlepay_s3_to_gcs")
        task_instance = TaskInstance(task, execution_date=execution_date)
        xcom_value = task_instance.xcom_pull()
        assert xcom_value is None

        captured = capsys.readouterr()
        assert "WARNING - File is not a psv type." in captured.out
