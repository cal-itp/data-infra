import os
from datetime import datetime, timezone

import pytest
from dateutil.relativedelta import relativedelta
from operators.gcs_to_ckan_operator import GCSToCKANOperator

from airflow.models.dag import DAG
from airflow.models.taskinstance import TaskInstance
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class TestGCSToCKANOperator:
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
    def operator(self, test_dag: DAG) -> GCSToCKANOperator:
        return GCSToCKANOperator(
            task_id="gcs_to_ckan",
            gcp_conn_id="google_cloud_default",
            bucket_name=os.environ.get("CALITP_BUCKET__PUBLISH"),
            object_name=os.path.join(
                "california_open_data__metadata",
                "dt=2025-06-01",
                "ts=2025-06-01T00:00:00+00:00",
                "metadata.csv",
            ),
            dataset_id="cal-itp-gtfs-ingest-pipeline-dataset",
            resource_name="Cal-ITP GTFS Schedule Metadata",
            ckan_conn_id="http_ckan",
            dag=test_dag,
        )

    @pytest.mark.vcr
    def test_execute(
        self,
        test_dag: DAG,
        operator: GCSToCKANOperator,
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

        task = test_dag.get_task("gcs_to_ckan")
        task_instance = TaskInstance(task, execution_date=execution_date)
        xcom_value = task_instance.xcom_pull()
        assert (
            xcom_value
            == {"partNumber": "1", "ETag": '"540ff57f389d699ed027208e2eba76a8"'}
            | xcom_value
        )
