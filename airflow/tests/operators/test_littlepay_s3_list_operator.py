from datetime import datetime, timezone

import pytest
from dateutil.relativedelta import relativedelta

from airflow.models.dag import DAG
from airflow.models.taskinstance import TaskInstance
from airflow.providers.amazon.aws.operators.s3 import S3ListOperator


class TestLittlepayS3ListOperator:
    @pytest.fixture
    def execution_date(self) -> datetime:
        return datetime.fromisoformat("2025-06-01").replace(tzinfo=timezone.utc)

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
    def operator(self, test_dag: DAG) -> S3ListOperator:
        return S3ListOperator(
            task_id="littlepay_s3_list",
            aws_conn_id="aws_atn",
            bucket="littlepay-datafeed-prod-atn-5c319c40",
            dag=test_dag,
        )

    @pytest.mark.vcr
    def test_execute(
        self,
        test_dag: DAG,
        operator: S3ListOperator,
        execution_date: datetime,
    ):
        operator.run(
            start_date=execution_date,
            end_date=execution_date
            + relativedelta(months=+1)
            - relativedelta(seconds=-1),
            ignore_first_depends_on_past=True,
        )

        task = test_dag.get_task("littlepay_s3_list")
        task_instance = TaskInstance(task, execution_date=execution_date)
        xcom_value = task_instance.xcom_pull()
        assert xcom_value[0] == "atn/v3/authorisations/202510241114_authorisations.psv"
