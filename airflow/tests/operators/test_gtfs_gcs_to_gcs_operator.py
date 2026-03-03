import json
import os
from datetime import datetime, timedelta, timezone

import pytest
from operators.gtfs_gcs_to_gcs_operator import GTFSGCSToGCSOperator

from airflow.models.dag import DAG
from airflow.models.taskinstance import TaskInstance
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class TestGTFSGCSToGCSOperator:
    @pytest.fixture
    def execution_date(self) -> datetime:
        return datetime.fromisoformat("2026-02-02").replace(tzinfo=timezone.utc)

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
    def download_config(self) -> dict:
        return {
            "auth_headers": {},
            "auth_query_params": {},
            "computed": False,
            "feed_type": "schedule",
            "name": "Example",
            "schedule_url_for_validation": None,
            "url": "https://example.com/gtfs.zip",
            "extracted_at": "2026-02-01T00:00:00+00:00",
        }

    @pytest.fixture
    def operator(self, download_config: dict, test_dag: DAG) -> GTFSGCSToGCSOperator:
        return GTFSGCSToGCSOperator(
            task_id="gtfs_gcs_to_gcs",
            gcp_conn_id="google_cloud_default",
            ts="2026-02-02T00:00:00+00:00",
            source_bucket=os.environ.get("CALITP_BUCKET__GTFS_SCHEDULE_MANUAL"),
            source_path="manual/base64_url=aHR0cHM6Ly9leGFtcGxlLmNvbS9ndGZzLnppcAo=/gtfs.zip",
            destination_bucket=os.environ.get("CALITP_BUCKET__GTFS_SCHEDULE_RAW"),
            destination_path="schedule/dt=2026-02-02/ts=2026-02-02T00:00:00+00:00/base64_url=aHR0cHM6Ly9leGFtcGxlLmNvbS9ndGZzLnppcAo=",
            download_config=download_config,
            dag=test_dag,
        )

    @pytest.mark.vcr
    def test_execute(
        self,
        test_dag: DAG,
        operator: GTFSGCSToGCSOperator,
        execution_date: datetime,
        download_config: dict,
        gcs_hook: GCSHook,
    ):
        operator.run(
            start_date=execution_date,
            end_date=execution_date + timedelta(days=1),
            ignore_first_depends_on_past=True,
        )

        task = test_dag.get_task("gtfs_gcs_to_gcs")
        task_instance = TaskInstance(task, execution_date=execution_date)
        xcom_value = task_instance.xcom_pull()
        assert xcom_value == {
            "schedule_feed_path": os.path.join(
                "schedule",
                "dt=2026-02-02",
                "ts=2026-02-02T00:00:00+00:00",
                "base64_url=aHR0cHM6Ly9leGFtcGxlLmNvbS9ndGZzLnppcAo=",
                "gtfs.zip",
            ),
            "extract": {
                "filename": "gtfs.zip",
                "ts": "2026-02-02T00:00:00+00:00",
                "config": download_config,
                "response_code": 200,
                "response_headers": {
                    "Content-Type": "application/zip",
                    "Content-Disposition": "attachment; filename=gtfs.zip",
                },
                "reconstructed": False,
            },
        }

        metadata = gcs_hook.get_metadata(
            bucket_name=os.environ.get("CALITP_BUCKET__GTFS_SCHEDULE_RAW").replace(
                "gs://", ""
            ),
            object_name=xcom_value["schedule_feed_path"],
        )
        parsed_metadata = json.loads(metadata["PARTITIONED_ARTIFACT_METADATA"])
        assert parsed_metadata == xcom_value["extract"] | {
            "ts": "2026-02-02T00:00:00+00:00",
            "response_headers": parsed_metadata["response_headers"],
        }
