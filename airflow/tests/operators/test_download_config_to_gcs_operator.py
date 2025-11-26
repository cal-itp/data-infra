import json
import os
from datetime import datetime, timedelta, timezone

import pytest
from operators.download_config_to_gcs_operator import DownloadConfigToGCSOperator

from airflow.models.dag import DAG
from airflow.models.taskinstance import TaskInstance
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class TestDownloadConfigToGCSOperator:
    @pytest.fixture
    def execution_date(self) -> datetime:
        return datetime.fromisoformat("2025-06-02").replace(tzinfo=timezone.utc)

    @pytest.fixture
    def gcs_hook(self) -> GCSHook:
        return GCSHook()

    @pytest.fixture
    def destination_path(self) -> str:
        return "schedule/dt=2025-06-02/ts=2025-06-02T00:00:00+00:00"

    @pytest.fixture
    def results_path(self) -> str:
        return (
            "download_schedule_feed_results/dt=2025-06-02/ts=2025-06-02T00:00:00+00:00"
        )

    @pytest.fixture
    def download_config(self) -> dict:
        return {
            "auth_headers": {},
            "auth_query_params": {},
            "computed": False,
            "feed_type": "schedule",
            "name": "Santa Ynez Mecatran Schedule",
            "schedule_url_for_validation": None,
            "url": "http://app.mecatran.com/urb/ws/feed/c2l0ZT1zeXZ0O2NsaWVudD1zZWxmO2V4cGlyZT07dHlwZT1ndGZzO2tleT00MjcwNzQ0ZTY4NTAzOTMyMDIxMDdjNzI0MDRkMzYyNTM4MzI0YzI0",
            "extracted_at": "2025-06-01T00:00:00+00:00",
        }

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
        download_config: dict,
        destination_path: str,
        results_path: str,
    ) -> DownloadConfigToGCSOperator:
        return DownloadConfigToGCSOperator(
            task_id="gtfs_download_config_to_gcs",
            gcp_conn_id="google_cloud_default",
            download_config=download_config,
            destination_bucket=os.environ.get("CALITP_BUCKET__GTFS_SCHEDULE_RAW"),
            destination_path=destination_path,
            results_path=results_path,
            dag=test_dag,
        )

    @pytest.mark.vcr
    def test_execute(
        self,
        test_dag: DAG,
        operator: DownloadConfigToGCSOperator,
        execution_date: datetime,
        destination_path: str,
        results_path: str,
        download_config: dict,
        gcs_hook: GCSHook,
    ):
        operator.run(
            start_date=execution_date,
            end_date=execution_date + timedelta(days=1),
            ignore_first_depends_on_past=True,
        )

        task = test_dag.get_task("gtfs_download_config_to_gcs")
        task_instance = TaskInstance(task, execution_date=execution_date)
        xcom_value = task_instance.xcom_pull()
        assert xcom_value == {
            "base64_url": "aHR0cDovL2FwcC5tZWNhdHJhbi5jb20vdXJiL3dzL2ZlZWQvYzJsMFpUMXplWFowTzJOc2FXVnVkRDF6Wld4bU8yVjRjR2x5WlQwN2RIbHdaVDFuZEdaek8ydGxlVDAwTWpjd056UTBaVFk0TlRBek9UTXlNREl4TURkak56STBNRFJrTXpZeU5UTTRNekkwWXpJMA==",
            "schedule_feed_path": os.path.join(
                "schedule",
                "dt=2025-06-02",
                "ts=2025-06-02T00:00:00+00:00",
                "base64_url=aHR0cDovL2FwcC5tZWNhdHJhbi5jb20vdXJiL3dzL2ZlZWQvYzJsMFpUMXplWFowTzJOc2FXVnVkRDF6Wld4bU8yVjRjR2x5WlQwN2RIbHdaVDFuZEdaek8ydGxlVDAwTWpjd056UTBaVFk0TlRBek9UTXlNREl4TURkak56STBNRFJrTXpZeU5UTTRNekkwWXpJMA==",
                "gtfs.zip",
            ),
            "download_schedule_feed_results": {
                "backfilled": False,
                "config": download_config,
                "exception": None,
                "extract": {
                    "filename": "gtfs.zip",
                    "ts": "2025-06-02T00:00:00+00:00",
                    "config": {
                        "auth_headers": {},
                        "auth_query_params": {},
                        "computed": False,
                        "feed_type": "schedule",
                        "name": "Santa Ynez Mecatran Schedule",
                        "schedule_url_for_validation": None,
                        "url": "http://app.mecatran.com/urb/ws/feed/c2l0ZT1zeXZ0O2NsaWVudD1zZWxmO2V4cGlyZT07dHlwZT1ndGZzO2tleT00MjcwNzQ0ZTY4NTAzOTMyMDIxMDdjNzI0MDRkMzYyNTM4MzI0YzI0",
                        "extracted_at": "2025-06-01T00:00:00+00:00",
                    },
                    "response_code": 200,
                    "response_headers": xcom_value["download_schedule_feed_results"][
                        "extract"
                    ]["response_headers"]
                    | {
                        "Content-Type": "application/zip",
                        "Content-Disposition": "attachment; filename=gtfs.zip",
                    },
                    "reconstructed": False,
                },
                "success": True,
            },
        }

        metadata = gcs_hook.get_metadata(
            bucket_name=os.environ.get("CALITP_BUCKET__GTFS_SCHEDULE_RAW").replace(
                "gs://", ""
            ),
            object_name=xcom_value["schedule_feed_path"],
        )
        parsed_metadata = json.loads(metadata["PARTITIONED_ARTIFACT_METADATA"])
        assert parsed_metadata == xcom_value["download_schedule_feed_results"][
            "extract"
        ] | {
            "ts": "2025-06-03T00:00:00+00:00",
            "response_headers": parsed_metadata["response_headers"],
        }

        decompressed_result = gcs_hook.download(
            bucket_name=os.environ.get("CALITP_BUCKET__GTFS_SCHEDULE_RAW").replace(
                "gs://", ""
            ),
            object_name=f"{results_path}/aHR0cDovL2FwcC5tZWNhdHJhbi5jb20vdXJiL3dzL2ZlZWQvYzJsMFpUMXplWFowTzJOc2FXVnVkRDF6Wld4bU8yVjRjR2x5WlQwN2RIbHdaVDFuZEdaek8ydGxlVDAwTWpjd056UTBaVFk0TlRBek9UTXlNREl4TURkak56STBNRFJrTXpZeU5UTTRNekkwWXpJMA==.jsonl",
        )
        result = json.loads(decompressed_result)
        assert result == {
            "success": True,
            "exception": None,
            "config": {
                "auth_headers": {},
                "auth_query_params": {},
                "computed": False,
                "feed_type": "schedule",
                "name": "Santa Ynez Mecatran Schedule",
                "schedule_url_for_validation": None,
                "url": "http://app.mecatran.com/urb/ws/feed/c2l0ZT1zeXZ0O2NsaWVudD1zZWxmO2V4cGlyZT07dHlwZT1ndGZzO2tleT00MjcwNzQ0ZTY4NTAzOTMyMDIxMDdjNzI0MDRkMzYyNTM4MzI0YzI0",
                "extracted_at": "2025-06-01T00:00:00+00:00",
            },
            "extract": {
                "filename": "gtfs.zip",
                "ts": "2025-06-03T00:00:00+00:00",
                "config": {
                    "auth_headers": {},
                    "auth_query_params": {},
                    "computed": False,
                    "feed_type": "schedule",
                    "name": "Santa Ynez Mecatran Schedule",
                    "schedule_url_for_validation": None,
                    "url": "http://app.mecatran.com/urb/ws/feed/c2l0ZT1zeXZ0O2NsaWVudD1zZWxmO2V4cGlyZT07dHlwZT1ndGZzO2tleT00MjcwNzQ0ZTY4NTAzOTMyMDIxMDdjNzI0MDRkMzYyNTM4MzI0YzI0",
                    "extracted_at": "2025-06-01T00:00:00+00:00",
                },
                "response_code": 200,
                "response_headers": result["extract"]["response_headers"]
                | {
                    "Content-Type": "application/zip",
                    "Content-Disposition": "attachment; filename=gtfs.zip",
                },
                "reconstructed": False,
            },
            "backfilled": False,
        }

        metadata = gcs_hook.get_metadata(
            bucket_name=os.environ.get("CALITP_BUCKET__GTFS_SCHEDULE_RAW").replace(
                "gs://", ""
            ),
            object_name=f"{results_path}/aHR0cDovL2FwcC5tZWNhdHJhbi5jb20vdXJiL3dzL2ZlZWQvYzJsMFpUMXplWFowTzJOc2FXVnVkRDF6Wld4bU8yVjRjR2x5WlQwN2RIbHdaVDFuZEdaek8ydGxlVDAwTWpjd056UTBaVFk0TlRBek9UTXlNREl4TURkak56STBNRFJrTXpZeU5UTTRNekkwWXpJMA==.jsonl",
        )
        assert json.loads(metadata["PARTITIONED_ARTIFACT_METADATA"]) == {
            "filename": "aHR0cDovL2FwcC5tZWNhdHJhbi5jb20vdXJiL3dzL2ZlZWQvYzJsMFpUMXplWFowTzJOc2FXVnVkRDF6Wld4bU8yVjRjR2x5WlQwN2RIbHdaVDFuZEdaek8ydGxlVDAwTWpjd056UTBaVFk0TlRBek9UTXlNREl4TURkak56STBNRFJrTXpZeU5UTTRNekkwWXpJMA==.jsonl",
            "ts": "2025-06-03T00:00:00+00:00",
            "end": "2025-06-03T00:00:00+00:00",
            "backfilled": False,
        }
