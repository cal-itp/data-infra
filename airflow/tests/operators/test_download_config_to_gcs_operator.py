import json
import os
from datetime import datetime, timedelta, timezone

import pytest
from operators.download_config_to_gcs_operator import DownloadConfigToGCSOperator

from airflow.exceptions import AirflowException
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
    def base64_url(self) -> str:
        return "aHR0cDovL2FwcC5tZWNhdHJhbi5jb20vdXJiL3dzL2ZlZWQvYzJsMFpUMXplWFowTzJOc2FXVnVkRDF6Wld4bU8yVjRjR2x5WlQwN2RIbHdaVDFuZEdaek8ydGxlVDAwTWpjd056UTBaVFk0TlRBek9UTXlNREl4TURkak56STBNRFJrTXpZeU5UTTRNekkwWXpJMA=="

    @pytest.fixture
    def destination_path(self, base64_url: str) -> str:
        return f"schedule/dt=2025-06-02/ts=2025-06-02T00:00:00+00:00/base64_url={base64_url}"

    @pytest.fixture
    def results_path(self, base64_url: str) -> str:
        return f"download_schedule_feed_results/dt=2025-06-02/ts=2025-06-02T00:00:00+00:00/{base64_url}.jsonl"

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
            "extracted_at": "2025-06-02T02:00:27.795513+00:00",
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
        execution_date: datetime,
        base64_url: str,
        destination_path: str,
        download_config: dict,
        results_path: str,
    ) -> DownloadConfigToGCSOperator:
        return DownloadConfigToGCSOperator(
            task_id="gtfs_download_config_to_gcs",
            gcp_conn_id="google_cloud_default",
            dt=execution_date.strftime("%Y-%m-%d"),
            ts=execution_date.isoformat(),
            dag=test_dag,
            download_config=download_config,
            base64_url=base64_url,
            source_bucket=os.environ.get("CALITP_BUCKET__GTFS_SCHEDULE_MANUAL"),
            source_path=os.path.join("manual", f"base64_url={base64_url}", "gtfs.zip"),
            destination_bucket=os.environ.get("CALITP_BUCKET__GTFS_SCHEDULE_RAW"),
            destination_path=destination_path,
            results_path=results_path,
        )

    @pytest.mark.vcr
    def test_execute(
        self,
        gcs_hook: GCSHook,
        execution_date: datetime,
        test_dag: DAG,
        operator: DownloadConfigToGCSOperator,
        base64_url: str,
        destination_path: str,
        download_config: dict,
        results_path: str,
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
            "dt": "2025-06-02",
            "ts": "2025-06-02T00:00:00+00:00",
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
                        "extracted_at": "2025-06-02T02:00:27.795513+00:00",
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
            "ts": "2025-06-02T00:00:00+00:00",
            "response_headers": parsed_metadata["response_headers"],
        }

        decompressed_result = gcs_hook.download(
            bucket_name=os.environ.get("CALITP_BUCKET__GTFS_SCHEDULE_RAW").replace(
                "gs://", ""
            ),
            object_name=results_path,
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
                "extracted_at": "2025-06-02T02:00:27.795513+00:00",
            },
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
                    "extracted_at": "2025-06-02T02:00:27.795513+00:00",
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
            object_name=results_path,
        )
        assert json.loads(metadata["PARTITIONED_ARTIFACT_METADATA"]) == {
            "filename": "aHR0cDovL2FwcC5tZWNhdHJhbi5jb20vdXJiL3dzL2ZlZWQvYzJsMFpUMXplWFowTzJOc2FXVnVkRDF6Wld4bU8yVjRjR2x5WlQwN2RIbHdaVDFuZEdaek8ydGxlVDAwTWpjd056UTBaVFk0TlRBek9UTXlNREl4TURkak56STBNRFJrTXpZeU5UTTRNekkwWXpJMA==.jsonl",
            "ts": "2025-06-02T00:00:00+00:00",
            "end": "2025-06-02T00:00:00+00:00",
            "backfilled": False,
        }

    @pytest.fixture
    def file_as_basename_download_config(self) -> dict:
        return {
            "auth_headers": {},
            "auth_query_params": {},
            "computed": False,
            "feed_type": "schedule",
            "name": "County Connection Schedule",
            "schedule_url_for_validation": None,
            "url": "http://cccta.org/GTFS/google_transit.zip",
            "extracted_at": "2025-06-02T02:00:27.795513+00:00",
        }

    @pytest.fixture
    def file_as_basename_base64_url(self) -> str:
        return "aHR0cDovL2NjY3RhLm9yZy9HVEZTL2dvb2dsZV90cmFuc2l0LnppcA=="

    @pytest.fixture
    def file_as_basename_destination_path(
        self, file_as_basename_base64_url: str
    ) -> str:
        return f"schedule/dt=2025-06-02/ts=2025-06-02T00:00:00+00:00/base64_url={file_as_basename_base64_url}"

    @pytest.fixture
    def file_as_basename_results_path(self, file_as_basename_base64_url: str) -> str:
        return f"download_schedule_feed_results/dt=2025-06-02/ts=2025-06-02T00:00:00+00:00/{file_as_basename_base64_url}.jsonl"

    @pytest.fixture
    def file_as_basename_dag(self, execution_date: datetime) -> DAG:
        return DAG(
            "file_as_basename_dag",
            default_args={
                "owner": "airflow",
                "start_date": execution_date,
                "end_date": execution_date + timedelta(days=1),
            },
            schedule=timedelta(days=1),
        )

    @pytest.fixture
    def file_as_basename_operator(
        self,
        execution_date: datetime,
        file_as_basename_dag: DAG,
        file_as_basename_base64_url: str,
        file_as_basename_destination_path: str,
        file_as_basename_download_config: dict,
        file_as_basename_results_path: str,
    ) -> DownloadConfigToGCSOperator:
        return DownloadConfigToGCSOperator(
            task_id="gtfs_download_config_to_gcs_basename",
            gcp_conn_id="google_cloud_default",
            dt=execution_date.strftime("%Y-%m-%d"),
            ts=execution_date.isoformat(),
            download_config=file_as_basename_download_config,
            base64_url=file_as_basename_base64_url,
            source_bucket=os.environ.get("CALITP_BUCKET__GTFS_SCHEDULE_MANUAL"),
            source_path=os.path.join(
                "manual", f"base64_url={file_as_basename_base64_url}", "gtfs.zip"
            ),
            destination_bucket=os.environ.get("CALITP_BUCKET__GTFS_SCHEDULE_RAW"),
            destination_path=file_as_basename_destination_path,
            results_path=file_as_basename_base64_url,
            dag=file_as_basename_dag,
        )

    @pytest.mark.vcr
    def test_execute_file_as_basename(
        self,
        gcs_hook: GCSHook,
        execution_date: datetime,
        file_as_basename_dag: DAG,
        file_as_basename_operator: DownloadConfigToGCSOperator,
        file_as_basename_base64_url: str,
        file_as_basename_destination_path: str,
        file_as_basename_download_config: dict,
        file_as_basename_results_path: str,
    ):
        file_as_basename_operator.run(
            start_date=execution_date,
            end_date=execution_date + timedelta(days=1),
            ignore_first_depends_on_past=True,
        )

        task = file_as_basename_dag.get_task("gtfs_download_config_to_gcs_basename")
        task_instance = TaskInstance(task, execution_date=execution_date)
        xcom_value = task_instance.xcom_pull()
        assert xcom_value == {
            "dt": "2025-06-02",
            "ts": "2025-06-02T00:00:00+00:00",
            "base64_url": "aHR0cDovL2NjY3RhLm9yZy9HVEZTL2dvb2dsZV90cmFuc2l0LnppcA==",
            "schedule_feed_path": os.path.join(
                "schedule",
                "dt=2025-06-02",
                "ts=2025-06-02T00:00:00+00:00",
                "base64_url=aHR0cDovL2NjY3RhLm9yZy9HVEZTL2dvb2dsZV90cmFuc2l0LnppcA==",
                "google_transit.zip",
            ),
            "download_schedule_feed_results": {
                "backfilled": False,
                "config": file_as_basename_download_config,
                "exception": None,
                "extract": {
                    "filename": "google_transit.zip",
                    "ts": "2025-06-02T00:00:00+00:00",
                    "config": file_as_basename_download_config,
                    "response_code": 200,
                    "response_headers": xcom_value["download_schedule_feed_results"][
                        "extract"
                    ]["response_headers"]
                    | {
                        "Content-Type": "application/zip",
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
            "ts": "2025-06-02T00:00:00+00:00",
            "response_headers": parsed_metadata["response_headers"],
        }

        decompressed_result = gcs_hook.download(
            bucket_name=os.environ.get("CALITP_BUCKET__GTFS_SCHEDULE_RAW").replace(
                "gs://", ""
            ),
            object_name=file_as_basename_results_path,
        )
        result = json.loads(decompressed_result)
        assert result == {
            "success": True,
            "exception": None,
            "config": file_as_basename_download_config,
            "extract": {
                "filename": "google_transit.zip",
                "ts": "2025-06-02T00:00:00+00:00",
                "config": file_as_basename_download_config,
                "response_code": 200,
                "response_headers": result["extract"]["response_headers"]
                | {
                    "Content-Type": "application/zip",
                },
                "reconstructed": False,
            },
            "backfilled": False,
        }

        metadata = gcs_hook.get_metadata(
            bucket_name=os.environ.get("CALITP_BUCKET__GTFS_SCHEDULE_RAW").replace(
                "gs://", ""
            ),
            object_name=file_as_basename_results_path,
        )
        assert json.loads(metadata["PARTITIONED_ARTIFACT_METADATA"]) == {
            "filename": "aHR0cDovL2NjY3RhLm9yZy9HVEZTL2dvb2dsZV90cmFuc2l0LnppcA==.jsonl",
            "ts": "2025-06-02T00:00:00+00:00",
            "end": "2025-06-02T00:00:00+00:00",
            "backfilled": False,
        }

    @pytest.fixture
    def file_as_response_basename_download_config(self) -> dict:
        return {
            "auth_headers": {},
            "auth_query_params": {},
            "computed": False,
            "feed_type": "schedule",
            "name": "Anteater Express Schedule",
            "schedule_url_for_validation": None,
            "url": "https://api.transloc.com/gtfs/uci.zip",
            "extracted_at": "2025-06-02T02:00:27.795513+00:00",
        }

    @pytest.fixture
    def file_as_response_basename_base64_url(self) -> str:
        return "aHR0cHM6Ly9hcGkudHJhbnNsb2MuY29tL2d0ZnMvdWNpLnppcA=="

    @pytest.fixture
    def file_as_response_basename_destination_path(
        self, file_as_response_basename_base64_url: str
    ) -> str:
        return f"schedule/dt=2025-06-02/ts=2025-06-02T00:00:00+00:00/base64_url={file_as_response_basename_base64_url}"

    @pytest.fixture
    def file_as_response_basename_results_path(
        self, file_as_response_basename_base64_url: str
    ) -> str:
        return f"download_schedule_feed_results/dt=2025-06-02/ts=2025-06-02T00:00:00+00:00/{file_as_response_basename_base64_url}.jsonl"

    @pytest.fixture
    def file_as_response_basename_dag(self, execution_date: datetime) -> DAG:
        return DAG(
            "file_as_response_basename_dag",
            default_args={
                "owner": "airflow",
                "start_date": execution_date,
                "end_date": execution_date + timedelta(days=1),
            },
            schedule=timedelta(days=1),
        )

    @pytest.fixture
    def file_as_response_basename_operator(
        self,
        execution_date: datetime,
        file_as_response_basename_dag: DAG,
        file_as_response_basename_base64_url: str,
        file_as_response_basename_download_config: dict,
        file_as_response_basename_destination_path: str,
        file_as_response_basename_results_path: str,
    ) -> DownloadConfigToGCSOperator:
        return DownloadConfigToGCSOperator(
            task_id="gtfs_download_config_to_gcs_basename",
            gcp_conn_id="google_cloud_default",
            dt=execution_date.strftime("%Y-%m-%d"),
            ts=execution_date.isoformat(),
            download_config=file_as_response_basename_download_config,
            base64_url=file_as_response_basename_base64_url,
            source_bucket=os.environ.get("CALITP_BUCKET__GTFS_SCHEDULE_MANUAL"),
            source_path=os.path.join(
                "manual",
                f"base64_url={file_as_response_basename_base64_url}",
                "gtfs.zip",
            ),
            destination_bucket=os.environ.get("CALITP_BUCKET__GTFS_SCHEDULE_RAW"),
            destination_path=file_as_response_basename_destination_path,
            results_path=file_as_response_basename_results_path,
            dag=file_as_response_basename_dag,
        )

    @pytest.mark.vcr
    def test_execute_file_as_response_basename(
        self,
        execution_date: datetime,
        gcs_hook: GCSHook,
        file_as_response_basename_dag: DAG,
        file_as_response_basename_operator: DownloadConfigToGCSOperator,
        file_as_response_basename_base64_url: str,
        file_as_response_basename_download_config: dict,
        file_as_response_basename_destination_path: str,
        file_as_response_basename_results_path: str,
    ):
        file_as_response_basename_operator.run(
            start_date=execution_date,
            end_date=execution_date + timedelta(days=1),
            ignore_first_depends_on_past=True,
        )

        task = file_as_response_basename_dag.get_task(
            "gtfs_download_config_to_gcs_basename"
        )
        task_instance = TaskInstance(task, execution_date=execution_date)
        xcom_value = task_instance.xcom_pull()
        assert xcom_value == {
            "dt": "2025-06-02",
            "ts": "2025-06-02T00:00:00+00:00",
            "base64_url": "aHR0cHM6Ly9hcGkudHJhbnNsb2MuY29tL2d0ZnMvdWNpLnppcA==",
            "schedule_feed_path": os.path.join(
                "schedule",
                "dt=2025-06-02",
                "ts=2025-06-02T00:00:00+00:00",
                "base64_url=aHR0cHM6Ly9hcGkudHJhbnNsb2MuY29tL2d0ZnMvdWNpLnppcA==",
                "export-2024-03-21T05-16-52.zip",
            ),
            "download_schedule_feed_results": {
                "backfilled": False,
                "config": file_as_response_basename_download_config,
                "exception": None,
                "extract": {
                    "filename": "export-2024-03-21T05-16-52.zip",
                    "ts": "2025-06-02T00:00:00+00:00",
                    "config": file_as_response_basename_download_config,
                    "response_code": 200,
                    "response_headers": xcom_value["download_schedule_feed_results"][
                        "extract"
                    ]["response_headers"]
                    | {
                        "Content-Type": "binary/octet-stream",
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
            "ts": "2025-06-02T00:00:00+00:00",
            "response_headers": parsed_metadata["response_headers"],
        }

        decompressed_result = gcs_hook.download(
            bucket_name=os.environ.get("CALITP_BUCKET__GTFS_SCHEDULE_RAW").replace(
                "gs://", ""
            ),
            object_name=file_as_response_basename_results_path,
        )
        result = json.loads(decompressed_result)
        assert result == {
            "success": True,
            "exception": None,
            "config": file_as_response_basename_download_config,
            "extract": {
                "filename": "export-2024-03-21T05-16-52.zip",
                "ts": "2025-06-02T00:00:00+00:00",
                "config": file_as_response_basename_download_config,
                "response_code": 200,
                "response_headers": result["extract"]["response_headers"]
                | {
                    "Content-Type": "binary/octet-stream",
                },
                "reconstructed": False,
            },
            "backfilled": False,
        }

        metadata = gcs_hook.get_metadata(
            bucket_name=os.environ.get("CALITP_BUCKET__GTFS_SCHEDULE_RAW").replace(
                "gs://", ""
            ),
            object_name=file_as_response_basename_results_path,
        )
        assert json.loads(metadata["PARTITIONED_ARTIFACT_METADATA"]) == {
            "filename": "aHR0cHM6Ly9hcGkudHJhbnNsb2MuY29tL2d0ZnMvdWNpLnppcA==.jsonl",
            "ts": "2025-06-02T00:00:00+00:00",
            "end": "2025-06-02T00:00:00+00:00",
            "backfilled": False,
        }

    @pytest.fixture
    def not_found_download_config(self) -> dict:
        return {
            "auth_headers": {},
            "auth_query_params": {},
            "computed": False,
            "feed_type": "schedule",
            "name": "CSUMB Campus Shuttles Schedule",
            "schedule_url_for_validation": None,
            "url": "https://csumb.edu/media/csumb/section-editors/facilities/the-wavex2ftransportation/CSUMB_gtfs.zip",
            "extracted_at": "2025-06-02T02:00:27.795513+00:00",
        }

    @pytest.fixture
    def not_found_base64_url(self) -> str:
        return "aHR0cHM6Ly9jc3VtYi5lZHUvbWVkaWEvY3N1bWIvc2VjdGlvbi1lZGl0b3JzL2ZhY2lsaXRpZXMvdGhlLXdhdmV4MmZ0cmFuc3BvcnRhdGlvbi9DU1VNQl9ndGZzLnppcA=="

    @pytest.fixture
    def not_found_destination_path(self, not_found_base64_url: str) -> str:
        return f"schedule/dt=2025-06-02/ts=2025-06-02T00:00:00+00:00/base64_url={not_found_base64_url}"

    @pytest.fixture
    def not_found_results_path(self, not_found_base64_url: str) -> str:
        return f"download_schedule_feed_results/dt=2025-06-02/ts=2025-06-02T00:00:00+00:00/{not_found_base64_url}.jsonl"

    @pytest.fixture
    def not_found_operator(
        self,
        test_dag: DAG,
        execution_date: datetime,
        not_found_destination_path: str,
        not_found_results_path: str,
        not_found_base64_url: str,
        not_found_download_config: dict,
    ) -> DownloadConfigToGCSOperator:
        return DownloadConfigToGCSOperator(
            task_id="gtfs_download_config_to_gcs_missing_results",
            gcp_conn_id="google_cloud_default",
            dt=execution_date.strftime("%Y-%m-%d"),
            ts=execution_date.isoformat(),
            download_config=not_found_download_config,
            base64_url=not_found_base64_url,
            source_bucket=os.environ.get("CALITP_BUCKET__GTFS_SCHEDULE_MANUAL"),
            source_path=os.path.join(
                "manual", f"base64_url={not_found_base64_url}", "gtfs.zip"
            ),
            destination_bucket=os.environ.get("CALITP_BUCKET__GTFS_SCHEDULE_RAW"),
            destination_path=not_found_destination_path,
            results_path=not_found_results_path,
            dag=test_dag,
        )

    @pytest.mark.vcr
    def test_execute_not_found(
        self,
        test_dag: DAG,
        execution_date: datetime,
        gcs_hook: GCSHook,
        not_found_operator: DownloadConfigToGCSOperator,
        not_found_base64_url: str,
        not_found_download_config: dict,
        not_found_destination_path: str,
        not_found_results_path: str,
    ):
        with pytest.raises(AirflowException) as exception:
            not_found_operator.run(
                start_date=execution_date,
                end_date=execution_date + timedelta(days=1),
                ignore_first_depends_on_past=True,
            )

        assert "404:Not Found" in str(exception.value)

        zip_file = gcs_hook.exists(
            bucket_name=os.environ.get("CALITP_BUCKET__GTFS_SCHEDULE_RAW").replace(
                "gs://", ""
            ),
            object_name=not_found_destination_path,
        )
        assert not zip_file

        download_result = gcs_hook.exists(
            bucket_name=os.environ.get("CALITP_BUCKET__GTFS_SCHEDULE_RAW").replace(
                "gs://", ""
            ),
            object_name=not_found_results_path,
        )
        assert not download_result

    @pytest.fixture
    def manual_download_config(self) -> dict:
        return {
            "auth_headers": {},
            "auth_query_params": {},
            "computed": False,
            "feed_type": "schedule",
            "name": "Example",
            "schedule_url_for_validation": None,
            "url": "https://example.com/gtfs.zip",
            "extracted_at": "2025-06-01T00:00:00+00:00",
        }

    @pytest.fixture
    def manual_download_base64_url(self) -> str:
        return "aHR0cHM6Ly9leGFtcGxlLmNvbS9ndGZzLnppcA=="

    @pytest.fixture
    def manual_download_destination_path(self, manual_download_base64_url: str) -> str:
        return f"schedule/dt=2025-06-02/ts=2025-06-02T00:00:00+00:00/base64_url={manual_download_base64_url}"

    @pytest.fixture
    def manual_download_results_path(self, manual_download_base64_url: str) -> str:
        return f"download_schedule_feed_results/dt=2025-06-02/ts=2025-06-02T00:00:00+00:00/{manual_download_base64_url}.jsonl"

    @pytest.fixture
    def manual_download_dag(self, execution_date: datetime) -> DAG:
        return DAG(
            "manual_download_dag",
            default_args={
                "owner": "airflow",
                "start_date": execution_date,
                "end_date": execution_date + timedelta(days=1),
            },
            schedule=timedelta(days=1),
        )

    @pytest.fixture
    def manual_download_operator(
        self,
        execution_date: datetime,
        manual_download_dag: DAG,
        manual_download_base64_url: str,
        manual_download_config: dict,
        manual_download_destination_path: str,
        manual_download_results_path: str,
    ) -> DownloadConfigToGCSOperator:
        return DownloadConfigToGCSOperator(
            task_id="manual_gtfs_download_config_to_gcs",
            gcp_conn_id="google_cloud_default",
            dt=execution_date.strftime("%Y-%m-%d"),
            ts=execution_date.isoformat(),
            download_config=manual_download_config,
            base64_url=manual_download_base64_url,
            source_bucket=os.environ.get("CALITP_BUCKET__GTFS_SCHEDULE_MANUAL"),
            source_path=os.path.join(
                "manual", f"base64_url={manual_download_base64_url}", "gtfs.zip"
            ),
            destination_bucket=os.environ.get("CALITP_BUCKET__GTFS_SCHEDULE_RAW"),
            destination_path=manual_download_destination_path,
            results_path=manual_download_results_path,
            dag=manual_download_dag,
        )

    @pytest.mark.vcr
    def test_manual_download_execute(
        self,
        manual_download_operator: DownloadConfigToGCSOperator,
        execution_date: datetime,
        gcs_hook: GCSHook,
        manual_download_dag: DAG,
        manual_download_base64_url: str,
        manual_download_config: dict,
        manual_download_destination_path: str,
        manual_download_results_path: str,
    ):
        manual_download_operator.run(
            start_date=execution_date,
            end_date=execution_date + timedelta(days=1),
            ignore_first_depends_on_past=True,
        )

        task = manual_download_dag.get_task("manual_gtfs_download_config_to_gcs")
        task_instance = TaskInstance(task, execution_date=execution_date)
        xcom_value = task_instance.xcom_pull()
        assert xcom_value == {
            "dt": "2025-06-02",
            "ts": "2025-06-02T00:00:00+00:00",
            "base64_url": "aHR0cHM6Ly9leGFtcGxlLmNvbS9ndGZzLnppcA==",
            "schedule_feed_path": os.path.join(
                "schedule",
                "dt=2025-06-02",
                "ts=2025-06-02T00:00:00+00:00",
                "base64_url=aHR0cHM6Ly9leGFtcGxlLmNvbS9ndGZzLnppcA==",
                "gtfs.zip",
            ),
            "download_schedule_feed_results": {
                "backfilled": False,
                "config": manual_download_config,
                "exception": None,
                "extract": {
                    "filename": "gtfs.zip",
                    "ts": "2025-06-02T00:00:00+00:00",
                    "config": manual_download_config,
                    "response_code": 200,
                    "response_headers": {
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
            "ts": "2025-06-02T00:00:00+00:00",
            "response_headers": {
                "Content-Type": "application/zip",
                "Content-Disposition": "attachment; filename=gtfs.zip",
            },
        }

        decompressed_result = gcs_hook.download(
            bucket_name=os.environ.get("CALITP_BUCKET__GTFS_SCHEDULE_RAW").replace(
                "gs://", ""
            ),
            object_name=manual_download_results_path,
        )
        result = json.loads(decompressed_result)
        assert result == {
            "success": True,
            "exception": None,
            "config": manual_download_config,
            "extract": {
                "filename": "gtfs.zip",
                "ts": "2025-06-02T00:00:00+00:00",
                "config": manual_download_config,
                "response_code": 200,
                "response_headers": {
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
            object_name=manual_download_results_path,
        )
        assert json.loads(metadata["PARTITIONED_ARTIFACT_METADATA"]) == {
            "filename": "aHR0cHM6Ly9leGFtcGxlLmNvbS9ndGZzLnppcA==.jsonl",
            "ts": "2025-06-02T00:00:00+00:00",
            "end": "2025-06-02T00:00:00+00:00",
            "backfilled": False,
        }
