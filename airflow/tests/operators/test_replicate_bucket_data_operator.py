import pytest

from datetime import datetime, timedelta, timezone
from operators.replicate_bucket_data_operator import ReplicateBucketDataOperator

from airflow.models.dag import DAG
from airflow.models.taskinstance import TaskInstance


class TestReplicateBucketDataOperator:
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
                "end_date": execution_date + timedelta(days=1),
            },
            schedule=timedelta(days=1),
        )

    @pytest.fixture
    def operator(self, test_dag: DAG) -> ReplicateBucketDataOperator:
        return ReplicateBucketDataOperator(
            task_id="replicate_bucket_data",
            origin_bucket="calitp-airtable",
            destination_bucket="calitp-staging-airtable",
            source_name="california_transit__services",
            source_date=datetime(2025, 6, 1),
            dag=test_dag,
        )

    @pytest.mark.vcr
    def test_execute(
        self,
        test_dag: DAG,
        operator: ReplicateBucketDataOperator,
        execution_date: datetime,
    ):
        operator.run(
            start_date=execution_date,
            end_date=execution_date + timedelta(hours=1) - timedelta(seconds=1),
            ignore_first_depends_on_past=True,
        )

        task = test_dag.get_task("replicate_bucket_data")
        task_instance = TaskInstance(task, execution_date=execution_date)
        xcom_value = task_instance.xcom_pull()
        assert xcom_value == "something"
