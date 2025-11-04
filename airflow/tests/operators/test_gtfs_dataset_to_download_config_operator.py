import gzip
import json
import os
from datetime import datetime, timedelta, timezone

import pytest
from operators.gtfs_dataset_to_download_config_operator import (
    GTFSDatasetToDownloadConfigOperator,
)

from airflow.models.dag import DAG
from airflow.models.taskinstance import TaskInstance
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class TestGTFSDatasetToDownloadConfigOperator:
    @pytest.fixture
    def execution_date(self) -> datetime:
        return datetime.fromisoformat("2025-06-01").replace(tzinfo=timezone.utc)

    @pytest.fixture
    def gcs_hook(self) -> GCSHook:
        return GCSHook()

    @pytest.fixture
    def source_path(self) -> str:
        return "california_transit__gtfs_datasets/dt=2025-06-01/ts=2025-06-01T00:00:00+00:00/gtfs_datasets.jsonl.gz"

    @pytest.fixture
    def destination_path(self) -> str:
        return "gtfs_download_configs/dt=2025-06-01/ts=2025-06-01T00:00:00+00:00/download_config.jsonl.gz"

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
        self, test_dag: DAG, source_path: str, destination_path: str
    ) -> GTFSDatasetToDownloadConfigOperator:
        return GTFSDatasetToDownloadConfigOperator(
            task_id="gtfs_dataset_to_download_config",
            gcp_conn_id="google_cloud_default",
            source_bucket=os.environ.get("CALITP_BUCKET__AIRTABLE"),
            source_path=source_path,
            destination_bucket=os.environ.get("CALITP_BUCKET__GTFS_DOWNLOAD_CONFIG"),
            destination_path=destination_path,
            dag=test_dag,
        )

    @pytest.mark.vcr
    def test_execute(
        self,
        test_dag: DAG,
        operator: GTFSDatasetToDownloadConfigOperator,
        execution_date: datetime,
        destination_path: str,
        gcs_hook: GCSHook,
    ):
        operator.run(
            start_date=execution_date,
            end_date=execution_date + timedelta(days=1),
            ignore_first_depends_on_past=True,
        )

        task = test_dag.get_task("gtfs_dataset_to_download_config")
        task_instance = TaskInstance(task, execution_date=execution_date)
        xcom_value = task_instance.xcom_pull()
        print("XCOM")
        print(xcom_value)
        assert xcom_value == os.path.join(
            os.environ.get("CALITP_BUCKET__GTFS_DOWNLOAD_CONFIG"),
            "gtfs_download_configs",
            "dt=2025-06-01",
            "ts=2025-06-01T00:00:00+00:00",
            "download_config.jsonl.gz",
        )

        compressed_result = gcs_hook.download(
            bucket_name=os.environ.get("CALITP_BUCKET__GTFS_DOWNLOAD_CONFIG").replace(
                "gs://", ""
            ),
            object_name=destination_path,
        )
        decompressed_result = gzip.decompress(compressed_result)
        result = [json.loads(x) for x in decompressed_result.splitlines()]

        assert result[0] == result[0] | {
            "data_quality_pipeline": True,
            "id": "rec00UyM37Kbq8qVw",
            "name": "Commerce VehiclePositions",
            "schedule_to_use_for_rt_validation": ["recEYdIhEXnEUNehu"],
            "pipeline_url": "https://citycommbus.com/gtfs-rt/vehiclepositions",
            "data": "GTFS VehiclePositions",
        }
