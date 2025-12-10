import csv
import os
from datetime import datetime, timezone
from io import StringIO

import pytest
from dateutil.relativedelta import relativedelta
from operators.littlepay_s3_to_gcs_operator import LittlepayS3ToGCSOperator

from airflow.models.dag import DAG
from airflow.models.taskinstance import TaskInstance
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class TestLittlepayS3ToGCSOperator:
    @pytest.fixture
    def execution_date(self) -> datetime:
        return datetime.fromisoformat("2025-06-01").replace(tzinfo=timezone.utc)

    @pytest.fixture
    def gcs_hook(self) -> GCSHook:
        return GCSHook()

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
    def operator(self, test_dag: DAG) -> LittlepayS3ToGCSOperator:
        return LittlepayS3ToGCSOperator(
            task_id="littlepay_s3_to_gcs",
            aws_conn_id="aws_atn",
            gcp_conn_id="google_cloud_default",
            source_bucket="littlepay-datafeed-prod-atn-5c319c40",
            source_path="atn/v3/authorisations/202510241114_authorisations.psv",
            destination_bucket=os.environ.get("CALITP_BUCKET__LITTLEPAY_RAW_V3"),
            destination_path="authorisations/instance=atn/filename=202510241114_authorisations.psv/ts=2025-06-01T00:00:00+00:00/202510241114_authorisations.psv",
            report_path="raw_littlepay_sync_job_result/instance=atn/ts=2025-06-01T00:00:00+00:00/202510241114_authorisations.jsonl",
            dag=test_dag,
        )

    @pytest.mark.vcr
    def test_execute(
        self,
        test_dag: DAG,
        operator: LittlepayS3ToGCSOperator,
        execution_date: datetime,
        gcs_hook: GCSHook,
    ):
        operator.run(
            start_date=execution_date,
            end_date=execution_date
            + relativedelta(months=+1)
            - relativedelta(seconds=-1),
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
        assert result[0] == {"tacos": True}

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
        assert result[0] == {"tacos": True}
