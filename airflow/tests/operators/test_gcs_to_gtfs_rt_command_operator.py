import os
from datetime import datetime, timedelta

import pytest
from operators.gcs_to_gtfs_rt_command_operator import GCSToGTFSRTCommandOperator

from airflow.models.dag import DAG
from airflow.models.taskinstance import TaskInstance


class TestGCSToGTFSRTCommandOperator:
    @pytest.fixture
    def execution_date(self) -> datetime:
        return datetime.fromisoformat("2024-10-22T18:15:00+00:00")

    @pytest.fixture
    def test_dag(self, execution_date: datetime) -> DAG:
        return DAG(
            "test_dag",
            default_args={
                "owner": "airflow",
                "start_date": execution_date,
                "end_date": execution_date + timedelta(hours=1),
            },
            schedule=timedelta(hours=1),
        )

    @pytest.fixture
    def operator(self, test_dag: DAG) -> GCSToGTFSRTCommandOperator:
        return GCSToGTFSRTCommandOperator(
            task_id="gcs_to_gtfs_rt_command",
            gcp_conn_id="google_cloud_default",
            process="parse",
            feed="service_alerts",
            bucket=os.environ.get("CALITP_BUCKET__GTFS_RT_RAW"),
            dag=test_dag,
        )

    @pytest.mark.vcr
    def test_execute(
        self,
        test_dag: DAG,
        operator: GCSToGTFSRTCommandOperator,
        execution_date: datetime,
    ):
        operator.run(
            start_date=execution_date,
            end_date=execution_date + timedelta(hours=1) - timedelta(seconds=1),
            ignore_first_depends_on_past=True,
        )

        task = test_dag.get_task("gcs_to_gtfs_rt_command")
        task_instance = TaskInstance(task, execution_date=execution_date)
        xcom_value = task_instance.xcom_pull()
        assert (
            "python3 "
            "$HOME/gcs/plugins/scripts/gtfs_rt_parser.py "
            "parse "
            "service_alerts "
            "2024-10-22T18:00:00 "
            "--base64url "
            "aHR0cHM6Ly90aGVidXNsaXZlLmNvbS9ndGZzLXJ0L2FsZXJ0cw== "
            "--verbose" in xcom_value
        )
