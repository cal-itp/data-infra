import gzip
import json
import os
from datetime import datetime, timezone

import pytest
from dateutil.relativedelta import relativedelta
from operators.blackcat_to_gcs_operator import BlackCatObjectPath, BlackCatToGCSOperator

from airflow.models.dag import DAG
from airflow.models.taskinstance import TaskInstance
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class TestBlackCatToGCSOperator:
    @pytest.fixture
    def execution_date(self) -> datetime:
        return datetime.fromisoformat("2025-06-01").replace(tzinfo=timezone.utc)

    @pytest.fixture
    def gcs_hook(self) -> GCSHook:
        return GCSHook()

    @pytest.fixture
    def object_path(self) -> BlackCatObjectPath:
        return BlackCatObjectPath(
            api_name="all_NTDReporting", file_name="all_ntdreports"
        )

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
    def operator(self, test_dag: DAG) -> BlackCatToGCSOperator:
        return BlackCatToGCSOperator(
            task_id="blackcat_to_gcs",
            http_conn_id="http_blackcat",
            gcp_conn_id="google_cloud_default",
            file_name="all_ntdreports",
            api_name="all_NTDReporting",
            bucket=os.environ.get("CALITP_BUCKET__NTD_REPORT_VALIDATION"),
            endpoint="/api/APIModules/GetNTDReportsByYear/BCG_CA/2025",
            dag=test_dag,
        )

    @pytest.mark.vcr
    def test_execute(
        self,
        test_dag: DAG,
        operator: BlackCatToGCSOperator,
        execution_date: datetime,
        object_path: BlackCatObjectPath,
        gcs_hook: GCSHook,
    ):
        operator.run(
            start_date=execution_date,
            end_date=execution_date
            + relativedelta(months=+1)
            - relativedelta(seconds=-1),
            ignore_first_depends_on_past=True,
        )

        task = test_dag.get_task("blackcat_to_gcs")
        task_instance = TaskInstance(task, execution_date=execution_date)
        xcom_value = task_instance.xcom_pull()
        assert xcom_value == os.path.join(
            os.environ.get("CALITP_BUCKET__NTD_REPORT_VALIDATION"),
            "all_NTDReporting",
            "year=2025",
            "dt=2025-06-01",
            "ts=2025-06-01T00:00:00+00:00",
            "all_ntdreports.jsonl.gz",
        )

        compressed_result = gcs_hook.download(
            bucket_name=os.environ.get("CALITP_BUCKET__NTD_REPORT_VALIDATION").replace(
                "gs://", ""
            ),
            object_name=object_path.resolve(execution_date),
        )
        decompressed_result = gzip.decompress(compressed_result)
        result = [json.loads(x) for x in decompressed_result.splitlines()]
        assert "ntdassetandresourceinfo" in result[0]
