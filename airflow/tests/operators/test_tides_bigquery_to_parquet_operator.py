import json
import os
from datetime import datetime, timedelta, timezone

import pytest
from operators.tides_bigquery_to_parquet_operator import TIDESBigQueryToParquetOperator

from airflow.models.dag import DAG
from airflow.models.taskinstance import TaskInstance
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class TestTIDESBigQueryToParquetOperator:
    @pytest.fixture
    def execution_date(self) -> datetime:
        return datetime.fromisoformat("2026-04-01").replace(tzinfo=timezone.utc)

    @pytest.fixture
    def gcs_hook(self) -> GCSHook:
        return GCSHook()

    @pytest.fixture
    def destination_path_prefix(self) -> str:
        return "vehicle_locations/organization_source_record_id=rec8zhnCPETu6qEiH/base64_url=aHR0cHM6Ly9yZWRvbmRvYmVhY2hiY3QuY29tL2d0ZnMtcnQvdmVoaWNsZXBvc2l0aW9ucw==/dt=2026-04-01/"

    @pytest.fixture
    def report_path(self) -> str:
        return "vehicle_locations_outcomes/dt=2026-04-01/ts=2026-04-01T00:00:00+00:00/organization_source_record_id=rec8zhnCPETu6qEiH/aHR0cHM6Ly9yZWRvbmRvYmVhY2hiY3QuY29tL2d0ZnMtcnQvdmVoaWNsZXBvc2l0aW9ucw==_outcomes.jsonl"

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
        self,
        test_dag: DAG,
        execution_date: datetime,
        destination_path_prefix: str,
        report_path: str,
    ) -> TIDESBigQueryToParquetOperator:
        return TIDESBigQueryToParquetOperator(
            task_id="vehicle_locations_export",
            dag=test_dag,
            dt=execution_date.strftime("%Y-%m-%d"),
            ts=execution_date.isoformat(),
            dataset_name="mart_tides",
            table_name="fct_tides_vehicle_locations",
            organization_source_record_id="rec8zhnCPETu6qEiH",
            base64_url="aHR0cHM6Ly9yZWRvbmRvYmVhY2hiY3QuY29tL2d0ZnMtcnQvdmVoaWNsZXBvc2l0aW9ucw==",
            display_name="Beach Cities VehiclePositions",
            destination_bucket=os.environ.get("CALITP_BUCKET__TIDES"),
            destination_path_prefix=destination_path_prefix,
            report_path=report_path,
            user_project=os.environ.get("GOOGLE_CLOUD_PROJECT"),
            gcp_conn_id="google_cloud_default",
        )

    @pytest.mark.vcr
    def test_execute(
        self,
        test_dag: DAG,
        operator: TIDESBigQueryToParquetOperator,
        execution_date: datetime,
        destination_path_prefix: str,
        report_path: str,
        gcs_hook: GCSHook,
    ):
        operator.run(
            start_date=execution_date,
            end_date=execution_date + timedelta(days=1),
            ignore_first_depends_on_past=True,
        )

        task = test_dag.get_task("vehicle_locations_export")
        task_instance = TaskInstance(task, execution_date=execution_date)
        xcom_value = task_instance.xcom_pull()
        assert xcom_value == {
            "organization_source_record_id": "rec8zhnCPETu6qEiH",
            "base64_url": "aHR0cHM6Ly9yZWRvbmRvYmVhY2hiY3QuY29tL2d0ZnMtcnQvdmVoaWNsZXBvc2l0aW9ucw==",
            "display_name": "Beach Cities VehiclePositions",
            "destination_path": os.path.join(
                destination_path_prefix,
                "data_*.parquet",
            ),
            "service_date": "2026-04-01",
            "ts": "2026-04-01T00:00:00+00:00",
        }

        parquet_files = gcs_hook.list(
            bucket_name=os.environ.get("CALITP_BUCKET__TIDES").replace("gs://", ""),
            match_glob=os.path.join(
                destination_path_prefix,
                "data_*.parquet",
            ),
        )
        assert len(parquet_files) == 101

        unparsed_outcomes = gcs_hook.download(
            bucket_name=os.environ.get("CALITP_BUCKET__TIDES").replace("gs://", ""),
            object_name=report_path,
        )
        outcomes = [json.loads(x) for x in unparsed_outcomes.splitlines()]

        assert outcomes[0] == {
            "dataset_name": "mart_tides",
            "table_name": "fct_tides_vehicle_locations",
            "organization_source_record_id": "rec8zhnCPETu6qEiH",
            "base64_url": "aHR0cHM6Ly9yZWRvbmRvYmVhY2hiY3QuY29tL2d0ZnMtcnQvdmVoaWNsZXBvc2l0aW9ucw==",
            "display_name": "Beach Cities VehiclePositions",
            "destination_path": os.path.join(
                destination_path_prefix,
                "data_*.parquet",
            ),
            "service_date": "2026-04-01",
            "ts": "2026-04-01T00:00:00+00:00",
        }
