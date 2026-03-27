import csv
import os
from datetime import datetime, timezone
from io import StringIO

import pytest
from dateutil.relativedelta import relativedelta
from moto import mock_aws
from operators.littlepay_raw_sync_feed_v3 import LittlepayRawSyncV3

from airflow.models.dag import DAG
from airflow.models.taskinstance import TaskInstance
from airflow.providers.amazon.aws.hooks.s3 import S3Hook
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class TestLittlepayRawSyncV3:
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
    def operator(self, test_dag: DAG) -> LittlepayRawSyncV3:
        return LittlepayRawSyncV3(
            task_id="littlepay_raw_sync_feed_v3",
            instance="atn",
            src_bucket="littlepay-datafeed-prod-atn-5c319c40",
            access_key_secret_name="LITTLEPAY_AWS_IAM_ATN_ACCESS_KEY_FEED_V3",
            dag=test_dag,
        )

    @mock_aws
    @pytest.mark.vcr
    def test_execute(
        self,
        test_dag: DAG,
        operator: LittlepayRawSyncV3,
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
            key="atn/v3/authorisations/202510241114_authorisations.psv",
            bucket_name="mock-littlepay-bucket",
        )

        operator.run(
            start_date=execution_date,
            end_date=execution_date
            + relativedelta(months=+1)
            - relativedelta(seconds=-1),
            ignore_first_depends_on_past=True,
        )

        task = test_dag.get_task("littlepay_raw_sync_feed_v3")
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

        psv_result = gcs_hook.download(
            bucket_name=os.environ.get("CALITP_BUCKET__LITTLEPAY_RAW_V3").replace(
                "gs://", ""
            ),
            object_name=xcom_value["report_path"],
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
