import json
import os
from datetime import datetime, timedelta, timezone

import pytest
from operators.bigquery_to_parquet_operator import BigQueryToParquetOperator

from airflow.models.dag import DAG
from airflow.models.taskinstance import TaskInstance
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class TestBigQueryToParquetOperator:
    @pytest.fixture
    def execution_date(self) -> datetime:
        return datetime.fromisoformat("2025-06-02").replace(tzinfo=timezone.utc)

    @pytest.fixture
    def gcs_hook(self) -> GCSHook:
        return GCSHook()

    @pytest.fixture
    def destination_path_prefix(self) -> str:
        return "vehicle_locations/dt=2025-06-02/ts=2025-06-02T00:00:00+00:00/gtfs_dataset_key=recUKDWE8Vq7rRAPM/"

    @pytest.fixture
    def report_path(self) -> str:
        return "vehicle_location_results/dt=2025-06-02/ts=2025-06-02T00:00:00+00:00/recUKDWE8Vq7rRAPM_results.jsonl"

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
    ) -> BigQueryToParquetOperator:
        return BigQueryToParquetOperator(
            task_id="vehicle_locations_export",
            dag=test_dag,
            dt=execution_date.strftime("%Y-%m-%d"),
            ts=execution_date.isoformat(),
            dataset_name="mart_tides",
            table_name="fct_tides_vehicle_locations",
            source_record_name="gtfs_dataset_key",
            source_record_id="recUKDWE8Vq7rRAPM",
            display_name="Beach Cities Transit",
            destination_bucket=os.environ.get("CALITP_BUCKET__TIDES"),
            destination_path_prefix=destination_path_prefix,
            report_path=report_path,
            gcp_conn_id="google_cloud_default",
        )

    @pytest.mark.vcr
    def test_execute(
        self,
        test_dag: DAG,
        operator: BigQueryToParquetOperator,
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
            "source_record_name": "gtfs_dataset_key",
            "source_record_id": "recUKDWE8Vq7rRAPM",
            "display_name": "Beach Cities Transit",
            "destination_uri": os.path.join(
                os.getenv("CALITP_BUCKET__TIDES"),
                destination_path_prefix,
                "recUKDWE8Vq7rRAPM_*.parquet",
            ),
            "dt": "2025-06-02",
            "ts": "2025-06-02T00:00:00+00:00",
        }

        parquet_files = gcs_hook.list(
            bucket_name=os.environ.get("CALITP_BUCKET__TIDES").replace("gs://", ""),
            match_glob=os.path.join(
                destination_path_prefix, "recUKDWE8Vq7rRAPM_*.parquet"
            ),
        )
        assert len(parquet_files) > 0

        unparsed_results = gcs_hook.download(
            bucket_name=os.environ.get("CALITP_BUCKET__TIDES").replace("gs://", ""),
            object_name=report_path,
        )
        results = [json.loads(x) for x in unparsed_results.splitlines()]

        assert results[0] == {
            "dataset_name": "mart_tides",
            "table_name": "fct_tides_vehicle_locations",
            "source_record_name": "gtfs_dataset_key",
            "source_record_id": "recUKDWE8Vq7rRAPM",
            "display_name": "Beach Cities Transit",
            "destination_uri": os.path.join(
                os.getenv("CALITP_BUCKET__TIDES"),
                destination_path_prefix,
                "recUKDWE8Vq7rRAPM_*.parquet",
            ),
            "dt": "2025-06-02",
            "ts": "2025-06-02T00:00:00+00:00",
        }
