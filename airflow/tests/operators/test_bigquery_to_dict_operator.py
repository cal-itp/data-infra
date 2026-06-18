from datetime import datetime, timedelta, timezone

import pytest
from operators.bigquery_to_dict_operator import BigQueryToDictOperator

from airflow.models.dag import DAG
from airflow.models.taskinstance import TaskInstance
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class TestBigQueryToDictOperator:
    @pytest.fixture
    def execution_date(self) -> datetime:
        return datetime.fromisoformat("2026-05-28").replace(tzinfo=timezone.utc)

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
                "end_date": execution_date + timedelta(days=1),
            },
            schedule=timedelta(days=1),
        )

    @pytest.fixture
    def operator(
        self, test_dag: DAG, execution_date: datetime
    ) -> BigQueryToDictOperator:
        return BigQueryToDictOperator(
            task_id="filter_bigquery_records",
            gcp_conn_id="google_cloud_default",
            dataset_name="mart_tides",
            table_name="tides_publication_feeds",
            select_columns=[
                "service_date",
                "organization_source_record_id",
                "vehicle_positions_source_record_id",
                "feed_name",
                "base64_url",
            ],
            filter_column="service_date",
            filter_value=(execution_date - timedelta(days=1)).strftime("%Y-%m-%d"),
            order_columns="service_date, feed_name",
            dag=test_dag,
        )

    @pytest.mark.vcr
    def test_execute(
        self,
        test_dag: DAG,
        operator: BigQueryToDictOperator,
        execution_date: datetime,
        gcs_hook: GCSHook,
    ):
        operator.run(
            start_date=execution_date,
            end_date=execution_date + timedelta(days=1),
            ignore_first_depends_on_past=True,
        )

        task = test_dag.get_task("filter_bigquery_records")
        task_instance = TaskInstance(task, execution_date=execution_date)
        xcom_value = task_instance.xcom_pull()
        assert xcom_value[0] == {
            "base64_url": "aHR0cHM6Ly9yZWRvbmRvYmVhY2hiY3QuY29tL2d0ZnMtcnQvdmVoaWNsZXBvc2l0aW9ucw==",
            "service_date": "2026-05-27",
            "feed_name": "Beach Cities VehiclePositions",
            "organization_source_record_id": "rec8zhnCPETu6qEiH",
            "vehicle_positions_source_record_id": "recUKDWE8Vq7rRAPM",
        }
