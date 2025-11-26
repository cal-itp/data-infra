import gzip
import json
import os
from datetime import datetime, timedelta, timezone

import pytest
from operators.bigquery_to_download_config_operator import (
    BigQueryToDownloadConfigOperator,
)

from airflow.models.dag import DAG
from airflow.models.taskinstance import TaskInstance
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class TestBigQueryToDownloadConfigOperator:
    @pytest.fixture
    def execution_date(self) -> datetime:
        return datetime.fromisoformat("2025-06-02").replace(tzinfo=timezone.utc)

    @pytest.fixture
    def gcs_hook(self) -> GCSHook:
        return GCSHook()

    @pytest.fixture
    def destination_path(self) -> str:
        return "gtfs_download_configs/dt=2025-06-02/ts=2025-06-02T00:00:00+00:00/download_config.jsonl.gz"

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
        self, test_dag: DAG, destination_path: str
    ) -> BigQueryToDownloadConfigOperator:
        return BigQueryToDownloadConfigOperator(
            task_id="gtfs_dataset_to_download_config",
            gcp_conn_id="google_cloud_default",
            dataset_name="staging",
            table_name="int_transit_database__gtfs_datasets_dim",
            destination_bucket=os.environ.get("CALITP_BUCKET__GTFS_DOWNLOAD_CONFIG"),
            destination_path=destination_path,
            dag=test_dag,
        )

    @pytest.mark.vcr
    def test_execute(
        self,
        test_dag: DAG,
        operator: BigQueryToDownloadConfigOperator,
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
        assert xcom_value == [{"destination_path": destination_path}]

        metadata = gcs_hook.get_metadata(
            bucket_name=os.environ.get("CALITP_BUCKET__GTFS_DOWNLOAD_CONFIG").replace(
                "gs://", ""
            ),
            object_name=destination_path,
        )
        assert metadata == {
            "PARTITIONED_ARTIFACT_METADATA": json.dumps(
                {"filename": "configs.jsonl.gz", "ts": "2025-06-03T00:00:00+00:00"}
            )
        }

        compressed_result = gcs_hook.download(
            bucket_name=os.environ.get("CALITP_BUCKET__GTFS_DOWNLOAD_CONFIG").replace(
                "gs://", ""
            ),
            object_name=destination_path,
        )
        decompressed_result = gzip.decompress(compressed_result)
        result = [json.loads(x) for x in decompressed_result.splitlines()]

        assert result[0] == {
            "extracted_at": "2025-06-03T00:00:00+00:00",
            "auth_headers": {},
            "auth_query_params": {},
            "computed": False,
            "feed_type": "schedule",
            "name": "Santa Ynez Mecatran Schedule",
            "schedule_url_for_validation": None,
            "url": "http://app.mecatran.com/urb/ws/feed/c2l0ZT1zeXZ0O2NsaWVudD1zZWxmO2V4cGlyZT07dHlwZT1ndGZzO2tleT00MjcwNzQ0ZTY4NTAzOTMyMDIxMDdjNzI0MDRkMzYyNTM4MzI0YzI0",
        }
