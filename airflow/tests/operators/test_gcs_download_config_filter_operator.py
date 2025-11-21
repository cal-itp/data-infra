import os
from datetime import datetime, timedelta, timezone

import pytest
from operators.gcs_download_config_filter_operator import (
    GCSDownloadConfigFilterOperator,
)

from airflow.models.dag import DAG
from airflow.models.taskinstance import TaskInstance
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class TestGCSDownloadConfigFilterOperator:
    @pytest.fixture
    def execution_date(self) -> datetime:
        return datetime.fromisoformat("2025-06-02").replace(tzinfo=timezone.utc)

    @pytest.fixture
    def gcs_hook(self) -> GCSHook:
        return GCSHook()

    @pytest.fixture
    def source_path(self) -> str:
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
        self, test_dag: DAG, source_path: str
    ) -> GCSDownloadConfigFilterOperator:
        return GCSDownloadConfigFilterOperator(
            task_id="gcs_download_config_filter",
            gcp_conn_id="google_cloud_default",
            feed_type="schedule",
            source_bucket=os.environ.get("CALITP_BUCKET__GTFS_DOWNLOAD_CONFIG"),
            source_path=source_path,
            dag=test_dag,
        )

    @pytest.mark.vcr
    def test_execute(
        self,
        test_dag: DAG,
        operator: GCSDownloadConfigFilterOperator,
        execution_date: datetime,
        source_path: str,
        gcs_hook: GCSHook,
    ):
        operator.run(
            start_date=execution_date,
            end_date=execution_date + timedelta(days=1),
            ignore_first_depends_on_past=True,
        )

        task = test_dag.get_task("gcs_download_config_filter")
        task_instance = TaskInstance(task, execution_date=execution_date)
        xcom_value = task_instance.xcom_pull()
        assert xcom_value[0] == {
            "extracted_at": "2025-06-03T00:00:00+00:00",
            "auth_headers": {},
            "auth_query_params": {},
            "computed": False,
            "feed_type": "schedule",
            "name": "Santa Ynez Mecatran Schedule",
            "schedule_url_for_validation": None,
            "url": "http://app.mecatran.com/urb/ws/feed/c2l0ZT1zeXZ0O2NsaWVudD1zZWxmO2V4cGlyZT07dHlwZT1ndGZzO2tleT00MjcwNzQ0ZTY4NTAzOTMyMDIxMDdjNzI0MDRkMzYyNTM4MzI0YzI0",
        }
