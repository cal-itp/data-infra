import gzip
import json
import os
from datetime import datetime, timedelta, timezone

import pytest
from operators.validate_gtfs_to_gcs_operator import ValidateGTFSToGCSOperator

from airflow.models.dag import DAG
from airflow.models.taskinstance import TaskInstance
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class TestValidateGTFSToGCSOperator:
    @pytest.fixture
    def execution_date(self) -> datetime:
        return datetime.fromisoformat("2025-06-02").replace(tzinfo=timezone.utc)

    @pytest.fixture
    def gcs_hook(self) -> GCSHook:
        return GCSHook()

    @pytest.fixture
    def source_path(self) -> str:
        return "schedule/dt=2025-06-02/ts=2025-06-02T00:00:00+00:00/base64_url=aHR0cDovL2FwcC5tZWNhdHJhbi5jb20vdXJiL3dzL2ZlZWQvYzJsMFpUMXplWFowTzJOc2FXVnVkRDF6Wld4bU8yVjRjR2x5WlQwN2RIbHdaVDFuZEdaek8ydGxlVDAwTWpjd056UTBaVFk0TlRBek9UTXlNREl4TURkak56STBNRFJrTXpZeU5UTTRNekkwWXpJMA==/gtfs.zip"

    @pytest.fixture
    def destination_path(self) -> str:
        return "validation_notices/dt=2025-06-02/ts=2025-06-02T00:00:00+00:00/base64_url=aHR0cDovL2FwcC5tZWNhdHJhbi5jb20vdXJiL3dzL2ZlZWQvYzJsMFpUMXplWFowTzJOc2FXVnVkRDF6Wld4bU8yVjRjR2x5WlQwN2RIbHdaVDFuZEdaek8ydGxlVDAwTWpjd056UTBaVFk0TlRBek9UTXlNREl4TURkak56STBNRFJrTXpZeU5UTTRNekkwWXpJMA=="

    @pytest.fixture
    def results_path(self) -> str:
        return "validation_job_results/dt=2025-06-02/ts=2025-06-02T00:00:00+00:00/aHR0cDovL2FwcC5tZWNhdHJhbi5jb20vdXJiL3dzL2ZlZWQvYzJsMFpUMXplWFowTzJOc2FXVnVkRDF6Wld4bU8yVjRjR2x5WlQwN2RIbHdaVDFuZEdaek8ydGxlVDAwTWpjd056UTBaVFk0TlRBek9UTXlNREl4TURkak56STBNRFJrTXpZeU5UTTRNekkwWXpJMA==.jsonl"

    @pytest.fixture
    def download_schedule_feed_results(self) -> dict:
        return {
            "backfilled": False,
            "config": {
                "auth_headers": {},
                "auth_query_params": {},
                "computed": False,
                "extracted_at": "2025-06-02T02:00:27.795513+00:00",
                "feed_type": "schedule",
                "name": "Santa Ynez Mecatran Schedule",
                "schedule_url_for_validation": None,
                "url": "http://app.mecatran.com/urb/ws/feed/c2l0ZT1zeXZ0O2NsaWVudD1zZWxmO2V4cGlyZT07dHlwZT1ndGZzO2tleT00MjcwNzQ0ZTY4NTAzOTMyMDIxMDdjNzI0MDRkMzYyNTM4MzI0YzI0",
            },
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
                "response_headers": {
                    "Content-Type": "application/zip",
                    "Content-Disposition": "attachment; filename=gtfs.zip",
                },
                "reconstructed": False,
            },
            "success": True,
        }

    @pytest.fixture
    def test_dag(self, execution_date: datetime) -> DAG:
        return DAG(
            "test_dag",
            default_args={
                "owner": "airflow",
                "start_date": execution_date - timedelta(days=1),
                "end_date": execution_date,
            },
            schedule=timedelta(days=1),
        )

    @pytest.fixture
    def operator(
        self,
        test_dag: DAG,
        execution_date: datetime,
        source_path: str,
        destination_path: str,
        results_path: str,
        download_schedule_feed_results: dict,
    ) -> ValidateGTFSToGCSOperator:
        return ValidateGTFSToGCSOperator(
            task_id="validate_gtfs_to_gcs",
            gcp_conn_id="google_cloud_default",
            dt=execution_date.strftime("%Y-%m-%d"),
            ts=execution_date.isoformat(),
            source_bucket=os.environ.get("CALITP_BUCKET__GTFS_SCHEDULE_RAW"),
            source_path=source_path,
            destination_bucket=os.environ.get(
                "CALITP_BUCKET__GTFS_SCHEDULE_VALIDATION_HOURLY"
            ),
            destination_path=destination_path,
            results_path=results_path,
            download_schedule_feed_results=download_schedule_feed_results,
            dag=test_dag,
        )

    @pytest.mark.vcr
    def test_execute(
        self,
        test_dag: DAG,
        operator: ValidateGTFSToGCSOperator,
        execution_date: datetime,
        source_path: str,
        gcs_hook: GCSHook,
    ):
        operator.run(
            start_date=execution_date - timedelta(days=1),
            end_date=execution_date,
            ignore_first_depends_on_past=True,
        )

        task = test_dag.get_task("validate_gtfs_to_gcs")
        task_instance = TaskInstance(task, execution_date=execution_date)
        xcom_value = task_instance.xcom_pull()
        assert xcom_value == {
            "dt": "2025-06-02",
            "ts": "2025-06-02T00:00:00+00:00",
            "destination_path": os.path.join(
                os.environ.get("CALITP_BUCKET__GTFS_SCHEDULE_VALIDATION_HOURLY"),
                "validation_notices",
                "dt=2025-06-02",
                "ts=2025-06-02T00:00:00+00:00",
                "base64_url=aHR0cDovL2FwcC5tZWNhdHJhbi5jb20vdXJiL3dzL2ZlZWQvYzJsMFpUMXplWFowTzJOc2FXVnVkRDF6Wld4bU8yVjRjR2x5WlQwN2RIbHdaVDFuZEdaek8ydGxlVDAwTWpjd056UTBaVFk0TlRBek9UTXlNREl4TURkak56STBNRFJrTXpZeU5UTTRNekkwWXpJMA==",
                "validation_notices_v5-0-0.jsonl.gz",
            ),
            "results_path": os.path.join(
                os.environ.get("CALITP_BUCKET__GTFS_SCHEDULE_VALIDATION_HOURLY"),
                "validation_job_results",
                "dt=2025-06-02",
                "ts=2025-06-02T00:00:00+00:00",
                "aHR0cDovL2FwcC5tZWNhdHJhbi5jb20vdXJiL3dzL2ZlZWQvYzJsMFpUMXplWFowTzJOc2FXVnVkRDF6Wld4bU8yVjRjR2x5WlQwN2RIbHdaVDFuZEdaek8ydGxlVDAwTWpjd056UTBaVFk0TlRBek9UTXlNREl4TURkak56STBNRFJrTXpZeU5UTTRNekkwWXpJMA==.jsonl",
            ),
        }

        compressed_notices = gcs_hook.download(
            bucket_name=os.environ.get(
                "CALITP_BUCKET__GTFS_SCHEDULE_VALIDATION_HOURLY"
            ).replace("gs://", ""),
            object_name="validation_notices/dt=2025-06-02/ts=2025-06-02T00:00:00+00:00/base64_url=aHR0cDovL2FwcC5tZWNhdHJhbi5jb20vdXJiL3dzL2ZlZWQvYzJsMFpUMXplWFowTzJOc2FXVnVkRDF6Wld4bU8yVjRjR2x5WlQwN2RIbHdaVDFuZEdaek8ydGxlVDAwTWpjd056UTBaVFk0TlRBek9UTXlNREl4TURkak56STBNRFJrTXpZeU5UTTRNekkwWXpJMA==/validation_notices_v5-0-0.jsonl.gz",
        )
        decompressed_notices = gzip.decompress(compressed_notices)
        notices = [json.loads(x) for x in decompressed_notices.splitlines()]
        assert notices[-1] == {
            "metadata": {
                "gtfs_validator_version": "v5.0.0",
                "extract_config": {
                    "auth_headers": {},
                    "auth_query_params": {},
                    "computed": False,
                    "extracted_at": "2025-06-02T02:00:27.795513+00:00",
                    "feed_type": "schedule",
                    "name": "Santa Ynez Mecatran Schedule",
                    "schedule_url_for_validation": None,
                    "url": "http://app.mecatran.com/urb/ws/feed/c2l0ZT1zeXZ0O2NsaWVudD1zZWxmO2V4cGlyZT07dHlwZT1ndGZzO2tleT00MjcwNzQ0ZTY4NTAzOTMyMDIxMDdjNzI0MDRkMzYyNTM4MzI0YzI0",
                },
            },
            "code": "unknown_file",
            "severity": "INFO",
            "totalNotices": 1,
            "sampleNotices": [{"filename": "route_directions.txt"}],
        }

        metadata = gcs_hook.get_metadata(
            bucket_name=os.environ.get(
                "CALITP_BUCKET__GTFS_SCHEDULE_VALIDATION_HOURLY"
            ).replace("gs://", ""),
            object_name="validation_notices/dt=2025-06-02/ts=2025-06-02T00:00:00+00:00/base64_url=aHR0cDovL2FwcC5tZWNhdHJhbi5jb20vdXJiL3dzL2ZlZWQvYzJsMFpUMXplWFowTzJOc2FXVnVkRDF6Wld4bU8yVjRjR2x5WlQwN2RIbHdaVDFuZEdaek8ydGxlVDAwTWpjd056UTBaVFk0TlRBek9UTXlNREl4TURkak56STBNRFJrTXpZeU5UTTRNekkwWXpJMA==/validation_notices_v5-0-0.jsonl.gz",
        )
        assert json.loads(metadata["PARTITIONED_ARTIFACT_METADATA"]) == {
            "filename": "validation_notices_v5-0-0.jsonl.gz",
            "ts": "2025-06-02T00:00:00+00:00",
            "extract_config": {
                "extracted_at": "2025-06-02T02:00:27.795513+00:00",
                "name": "Santa Ynez Mecatran Schedule",
                "url": "http://app.mecatran.com/urb/ws/feed/c2l0ZT1zeXZ0O2NsaWVudD1zZWxmO2V4cGlyZT07dHlwZT1ndGZzO2tleT00MjcwNzQ0ZTY4NTAzOTMyMDIxMDdjNzI0MDRkMzYyNTM4MzI0YzI0",
                "feed_type": "schedule",
                "schedule_url_for_validation": None,
                "auth_query_params": {},
                "auth_headers": {},
                "computed": False,
            },
            "system_errors": {"notices": []},
            "validator_version": "v5.0.0",
        }

        unparsed_results = gcs_hook.download(
            bucket_name=os.environ.get(
                "CALITP_BUCKET__GTFS_SCHEDULE_VALIDATION_HOURLY"
            ).replace("gs://", ""),
            object_name="validation_job_results/dt=2025-06-02/ts=2025-06-02T00:00:00+00:00/aHR0cDovL2FwcC5tZWNhdHJhbi5jb20vdXJiL3dzL2ZlZWQvYzJsMFpUMXplWFowTzJOc2FXVnVkRDF6Wld4bU8yVjRjR2x5WlQwN2RIbHdaVDFuZEdaek8ydGxlVDAwTWpjd056UTBaVFk0TlRBek9UTXlNREl4TURkak56STBNRFJrTXpZeU5UTTRNekkwWXpJMA==.jsonl",
        )
        results = json.loads(unparsed_results)
        assert results == {
            "validation": {
                "filename": "validation_notices_v5-0-0.jsonl.gz",
                "system_errors": {"notices": []},
                "validator_version": "v5.0.0",
                "extract_config": {
                    "auth_headers": {},
                    "auth_query_params": {},
                    "computed": False,
                    "extracted_at": "2025-06-02T02:00:27.795513+00:00",
                    "feed_type": "schedule",
                    "name": "Santa Ynez Mecatran Schedule",
                    "schedule_url_for_validation": None,
                    "url": "http://app.mecatran.com/urb/ws/feed/c2l0ZT1zeXZ0O2NsaWVudD1zZWxmO2V4cGlyZT07dHlwZT1ndGZzO2tleT00MjcwNzQ0ZTY4NTAzOTMyMDIxMDdjNzI0MDRkMzYyNTM4MzI0YzI0",
                },
                "ts": "2025-06-02T00:00:00+00:00",
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
                "response_headers": {
                    "Content-Type": "application/zip",
                    "Content-Disposition": "attachment; filename=gtfs.zip",
                },
                "reconstructed": False,
            },
            "success": True,
            "exception": None,
        }

        metadata = gcs_hook.get_metadata(
            bucket_name=os.environ.get(
                "CALITP_BUCKET__GTFS_SCHEDULE_VALIDATION_HOURLY"
            ).replace("gs://", ""),
            object_name="validation_job_results/dt=2025-06-02/ts=2025-06-02T00:00:00+00:00/aHR0cDovL2FwcC5tZWNhdHJhbi5jb20vdXJiL3dzL2ZlZWQvYzJsMFpUMXplWFowTzJOc2FXVnVkRDF6Wld4bU8yVjRjR2x5WlQwN2RIbHdaVDFuZEdaek8ydGxlVDAwTWpjd056UTBaVFk0TlRBek9UTXlNREl4TURkak56STBNRFJrTXpZeU5UTTRNekkwWXpJMA==.jsonl",
        )
        assert json.loads(metadata["PARTITIONED_ARTIFACT_METADATA"]) == {
            "filename": "results.jsonl",
            "ts": "2025-06-02T00:00:00+00:00",
        }

    @pytest.fixture
    def rerun_execution_date(self) -> datetime:
        return datetime.fromisoformat("2025-06-03").replace(tzinfo=timezone.utc)

    @pytest.fixture
    def rerun_destination_path(self) -> str:
        return "validation_notices/dt=2025-06-03/ts=2025-06-03T00:00:00+00:00/base64_url=aHR0cDovL2FwcC5tZWNhdHJhbi5jb20vdXJiL3dzL2ZlZWQvYzJsMFpUMXplWFowTzJOc2FXVnVkRDF6Wld4bU8yVjRjR2x5WlQwN2RIbHdaVDFuZEdaek8ydGxlVDAwTWpjd056UTBaVFk0TlRBek9UTXlNREl4TURkak56STBNRFJrTXpZeU5UTTRNekkwWXpJMA=="

    @pytest.fixture
    def rerun_results_path(self) -> str:
        return "validation_job_results/dt=2025-06-03/ts=2025-06-03T00:00:00+00:00/aHR0cDovL2FwcC5tZWNhdHJhbi5jb20vdXJiL3dzL2ZlZWQvYzJsMFpUMXplWFowTzJOc2FXVnVkRDF6Wld4bU8yVjRjR2x5WlQwN2RIbHdaVDFuZEdaek8ydGxlVDAwTWpjd056UTBaVFk0TlRBek9UTXlNREl4TURkak56STBNRFJrTXpZeU5UTTRNekkwWXpJMA==.jsonl"

    @pytest.fixture
    def rerun_download_schedule_feed_results(self) -> dict:
        return {
            "backfilled": False,
            "config": {
                "auth_headers": {},
                "auth_query_params": {},
                "computed": False,
                "extracted_at": "2025-06-02T02:00:27.795513+00:00",
                "feed_type": "schedule",
                "name": "Santa Ynez Mecatran Schedule",
                "schedule_url_for_validation": None,
                "url": "http://app.mecatran.com/urb/ws/feed/c2l0ZT1zeXZ0O2NsaWVudD1zZWxmO2V4cGlyZT07dHlwZT1ndGZzO2tleT00MjcwNzQ0ZTY4NTAzOTMyMDIxMDdjNzI0MDRkMzYyNTM4MzI0YzI0",
            },
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
                "response_headers": {
                    "Content-Type": "application/zip",
                    "Content-Disposition": "attachment; filename=gtfs.zip",
                },
                "reconstructed": False,
            },
            "success": True,
        }

    @pytest.fixture
    def rerun_test_dag(self, execution_date: datetime) -> DAG:
        return DAG(
            "rerun_test_dag",
            default_args={
                "owner": "airflow",
                "start_date": execution_date - timedelta(days=1),
                "end_date": execution_date,
            },
            schedule=timedelta(days=1),
        )

    @pytest.fixture
    def rerun_operator(
        self,
        rerun_test_dag: DAG,
        rerun_execution_date: datetime,
        source_path: str,
        rerun_destination_path: str,
        rerun_results_path: str,
        rerun_download_schedule_feed_results: dict,
    ) -> ValidateGTFSToGCSOperator:
        return ValidateGTFSToGCSOperator(
            task_id="validate_gtfs_to_gcs_rerun",
            gcp_conn_id="google_cloud_default",
            dt=rerun_execution_date.strftime("%Y-%m-%d"),
            ts=rerun_execution_date.isoformat(),
            source_bucket=os.environ.get("CALITP_BUCKET__GTFS_SCHEDULE_RAW"),
            source_path=source_path,
            destination_bucket=os.environ.get(
                "CALITP_BUCKET__GTFS_SCHEDULE_VALIDATION_HOURLY"
            ),
            destination_path=rerun_destination_path,
            results_path=rerun_results_path,
            download_schedule_feed_results=rerun_download_schedule_feed_results,
            dag=rerun_test_dag,
        )

    @pytest.mark.vcr
    def test_rerun_execute(
        self,
        rerun_test_dag: DAG,
        rerun_operator: ValidateGTFSToGCSOperator,
        execution_date: datetime,
        source_path: str,
        gcs_hook: GCSHook,
    ):
        rerun_operator.run(
            start_date=execution_date - timedelta(days=1),
            end_date=execution_date,
            ignore_first_depends_on_past=True,
        )

        task = rerun_test_dag.get_task("validate_gtfs_to_gcs_rerun")
        task_instance = TaskInstance(task, execution_date=execution_date)
        xcom_value = task_instance.xcom_pull()
        assert xcom_value == {
            "dt": "2025-06-03",
            "ts": "2025-06-03T00:00:00+00:00",
            "destination_path": os.path.join(
                os.environ.get("CALITP_BUCKET__GTFS_SCHEDULE_VALIDATION_HOURLY"),
                "validation_notices",
                "dt=2025-06-03",
                "ts=2025-06-03T00:00:00+00:00",
                "base64_url=aHR0cDovL2FwcC5tZWNhdHJhbi5jb20vdXJiL3dzL2ZlZWQvYzJsMFpUMXplWFowTzJOc2FXVnVkRDF6Wld4bU8yVjRjR2x5WlQwN2RIbHdaVDFuZEdaek8ydGxlVDAwTWpjd056UTBaVFk0TlRBek9UTXlNREl4TURkak56STBNRFJrTXpZeU5UTTRNekkwWXpJMA==",
                "validation_notices_v5-0-0.jsonl.gz",
            ),
            "results_path": os.path.join(
                os.environ.get("CALITP_BUCKET__GTFS_SCHEDULE_VALIDATION_HOURLY"),
                "validation_job_results",
                "dt=2025-06-03",
                "ts=2025-06-03T00:00:00+00:00",
                "aHR0cDovL2FwcC5tZWNhdHJhbi5jb20vdXJiL3dzL2ZlZWQvYzJsMFpUMXplWFowTzJOc2FXVnVkRDF6Wld4bU8yVjRjR2x5WlQwN2RIbHdaVDFuZEdaek8ydGxlVDAwTWpjd056UTBaVFk0TlRBek9UTXlNREl4TURkak56STBNRFJrTXpZeU5UTTRNekkwWXpJMA==.jsonl",
            ),
        }

        compressed_notices = gcs_hook.download(
            bucket_name=os.environ.get(
                "CALITP_BUCKET__GTFS_SCHEDULE_VALIDATION_HOURLY"
            ).replace("gs://", ""),
            object_name="validation_notices/dt=2025-06-03/ts=2025-06-03T00:00:00+00:00/base64_url=aHR0cDovL2FwcC5tZWNhdHJhbi5jb20vdXJiL3dzL2ZlZWQvYzJsMFpUMXplWFowTzJOc2FXVnVkRDF6Wld4bU8yVjRjR2x5WlQwN2RIbHdaVDFuZEdaek8ydGxlVDAwTWpjd056UTBaVFk0TlRBek9UTXlNREl4TURkak56STBNRFJrTXpZeU5UTTRNekkwWXpJMA==/validation_notices_v5-0-0.jsonl.gz",
        )
        decompressed_notices = gzip.decompress(compressed_notices)
        notices = [json.loads(x) for x in decompressed_notices.splitlines()]
        assert notices[-1] == {
            "metadata": {
                "gtfs_validator_version": "v5.0.0",
                "extract_config": {
                    "auth_headers": {},
                    "auth_query_params": {},
                    "computed": False,
                    "extracted_at": "2025-06-02T02:00:27.795513+00:00",
                    "feed_type": "schedule",
                    "name": "Santa Ynez Mecatran Schedule",
                    "schedule_url_for_validation": None,
                    "url": "http://app.mecatran.com/urb/ws/feed/c2l0ZT1zeXZ0O2NsaWVudD1zZWxmO2V4cGlyZT07dHlwZT1ndGZzO2tleT00MjcwNzQ0ZTY4NTAzOTMyMDIxMDdjNzI0MDRkMzYyNTM4MzI0YzI0",
                },
            },
            "code": "unknown_file",
            "severity": "INFO",
            "totalNotices": 1,
            "sampleNotices": [{"filename": "route_directions.txt"}],
        }

        metadata = gcs_hook.get_metadata(
            bucket_name=os.environ.get(
                "CALITP_BUCKET__GTFS_SCHEDULE_VALIDATION_HOURLY"
            ).replace("gs://", ""),
            object_name="validation_notices/dt=2025-06-03/ts=2025-06-03T00:00:00+00:00/base64_url=aHR0cDovL2FwcC5tZWNhdHJhbi5jb20vdXJiL3dzL2ZlZWQvYzJsMFpUMXplWFowTzJOc2FXVnVkRDF6Wld4bU8yVjRjR2x5WlQwN2RIbHdaVDFuZEdaek8ydGxlVDAwTWpjd056UTBaVFk0TlRBek9UTXlNREl4TURkak56STBNRFJrTXpZeU5UTTRNekkwWXpJMA==/validation_notices_v5-0-0.jsonl.gz",
        )
        assert json.loads(metadata["PARTITIONED_ARTIFACT_METADATA"]) == {
            "filename": "validation_notices_v5-0-0.jsonl.gz",
            "ts": "2025-06-02T00:00:00+00:00",
            "extract_config": {
                "extracted_at": "2025-06-02T02:00:27.795513+00:00",
                "name": "Santa Ynez Mecatran Schedule",
                "url": "http://app.mecatran.com/urb/ws/feed/c2l0ZT1zeXZ0O2NsaWVudD1zZWxmO2V4cGlyZT07dHlwZT1ndGZzO2tleT00MjcwNzQ0ZTY4NTAzOTMyMDIxMDdjNzI0MDRkMzYyNTM4MzI0YzI0",
                "feed_type": "schedule",
                "schedule_url_for_validation": None,
                "auth_query_params": {},
                "auth_headers": {},
                "computed": False,
            },
            "system_errors": {"notices": []},
            "validator_version": "v5.0.0",
        }

        unparsed_results = gcs_hook.download(
            bucket_name=os.environ.get(
                "CALITP_BUCKET__GTFS_SCHEDULE_VALIDATION_HOURLY"
            ).replace("gs://", ""),
            object_name="validation_job_results/dt=2025-06-03/ts=2025-06-03T00:00:00+00:00/aHR0cDovL2FwcC5tZWNhdHJhbi5jb20vdXJiL3dzL2ZlZWQvYzJsMFpUMXplWFowTzJOc2FXVnVkRDF6Wld4bU8yVjRjR2x5WlQwN2RIbHdaVDFuZEdaek8ydGxlVDAwTWpjd056UTBaVFk0TlRBek9UTXlNREl4TURkak56STBNRFJrTXpZeU5UTTRNekkwWXpJMA==.jsonl",
        )
        results = json.loads(unparsed_results)
        assert results == {
            "validation": {
                "filename": "validation_notices_v5-0-0.jsonl.gz",
                "system_errors": {"notices": []},
                "validator_version": "v5.0.0",
                "extract_config": {
                    "auth_headers": {},
                    "auth_query_params": {},
                    "computed": False,
                    "extracted_at": "2025-06-02T02:00:27.795513+00:00",
                    "feed_type": "schedule",
                    "name": "Santa Ynez Mecatran Schedule",
                    "schedule_url_for_validation": None,
                    "url": "http://app.mecatran.com/urb/ws/feed/c2l0ZT1zeXZ0O2NsaWVudD1zZWxmO2V4cGlyZT07dHlwZT1ndGZzO2tleT00MjcwNzQ0ZTY4NTAzOTMyMDIxMDdjNzI0MDRkMzYyNTM4MzI0YzI0",
                },
                "ts": "2025-06-02T00:00:00+00:00",
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
                "response_headers": {
                    "Content-Type": "application/zip",
                    "Content-Disposition": "attachment; filename=gtfs.zip",
                },
                "reconstructed": False,
            },
            "success": True,
            "exception": None,
        }

        metadata = gcs_hook.get_metadata(
            bucket_name=os.environ.get(
                "CALITP_BUCKET__GTFS_SCHEDULE_VALIDATION_HOURLY"
            ).replace("gs://", ""),
            object_name="validation_job_results/dt=2025-06-03/ts=2025-06-03T00:00:00+00:00/aHR0cDovL2FwcC5tZWNhdHJhbi5jb20vdXJiL3dzL2ZlZWQvYzJsMFpUMXplWFowTzJOc2FXVnVkRDF6Wld4bU8yVjRjR2x5WlQwN2RIbHdaVDFuZEdaek8ydGxlVDAwTWpjd056UTBaVFk0TlRBek9UTXlNREl4TURkak56STBNRFJrTXpZeU5UTTRNekkwWXpJMA==.jsonl",
        )
        assert json.loads(metadata["PARTITIONED_ARTIFACT_METADATA"]) == {
            "filename": "results.jsonl",
            "ts": "2025-06-03T00:00:00+00:00",
        }

    @pytest.fixture
    def empty_execution_date(self) -> datetime:
        return datetime.fromisoformat("2025-11-13T03:02:04.189504+00:00")

    @pytest.fixture
    def empty_source_path(self) -> str:
        return "schedule/dt=2025-11-13/ts=2025-11-13T03:02:04.189504+00:00/base64_url=aHR0cHM6Ly93d3cuaXBzLXN5c3RlbXMuY29tL0dURlMvU2NoZWR1bGUvMjc=/schedule-27.zip"

    @pytest.fixture
    def empty_destination_path(self) -> str:
        return "validation_notices/dt=2025-11-13/ts=2025-11-13T03:02:04.189504+00:00/base64_url=aHR0cHM6Ly93d3cuaXBzLXN5c3RlbXMuY29tL0dURlMvU2NoZWR1bGUvMjc="

    @pytest.fixture
    def empty_results_path(self) -> str:
        return "validation_job_results/dt=2025-11-13/ts=2025-11-13T03:02:04.189504+00:00/aHR0cHM6Ly93d3cuaXBzLXN5c3RlbXMuY29tL0dURlMvU2NoZWR1bGUvMjc=.jsonl"

    @pytest.fixture
    def empty_download_schedule_feed_results(self) -> dict:
        return {
            "backfilled": False,
            "config": {
                "auth_headers": {},
                "auth_query_params": {},
                "computed": False,
                "extracted_at": "2025-11-12T02:00:00+00:00",
                "feed_type": "schedule",
                "name": "Fric and Frac Schedule",
                "schedule_url_for_validation": None,
                "url": "https://www.ips-systems.com/GTFS/Schedule/27",
            },
            "exception": None,
            "extract": {
                "filename": "schedule-27.zip",
                "ts": "2025-11-13T03:02:04.189504+00:00",
                "config": {
                    "auth_headers": {},
                    "auth_query_params": {},
                    "computed": False,
                    "extracted_at": "2025-11-12T02:00:00+00:00",
                    "feed_type": "schedule",
                    "name": "Fric and Frac Schedule",
                    "schedule_url_for_validation": None,
                    "url": "https://www.ips-systems.com/GTFS/Schedule/27",
                },
                "response_code": 200,
                "response_headers": {
                    "Content-Type": "application/zip",
                    "Content-Disposition": "attachment; filename=schedule-27.zip",
                },
                "reconstructed": False,
            },
            "success": True,
        }

    @pytest.fixture
    def test_empty_dag(self, empty_execution_date: datetime) -> DAG:
        return DAG(
            "test_dag_calendar_dates_empty",
            default_args={
                "owner": "airflow",
                "start_date": empty_execution_date - timedelta(days=1),
                "end_date": empty_execution_date,
            },
            schedule=timedelta(days=1),
        )

    @pytest.fixture
    def empty_operator(
        self,
        test_empty_dag: DAG,
        empty_execution_date: datetime,
        empty_source_path: str,
        empty_destination_path: str,
        empty_results_path: str,
        empty_download_schedule_feed_results: dict,
    ) -> ValidateGTFSToGCSOperator:
        return ValidateGTFSToGCSOperator(
            task_id="validate_gtfs_to_gcs_calendar_dates_empty",
            gcp_conn_id="google_cloud_default",
            dt=empty_execution_date.strftime("%Y-%m-%d"),
            ts=empty_execution_date.isoformat(),
            source_bucket=os.environ.get("CALITP_BUCKET__GTFS_SCHEDULE_RAW"),
            source_path=empty_source_path,
            destination_bucket=os.environ.get(
                "CALITP_BUCKET__GTFS_SCHEDULE_VALIDATION_HOURLY"
            ),
            destination_path=empty_destination_path,
            results_path=empty_results_path,
            download_schedule_feed_results=empty_download_schedule_feed_results,
            dag=test_empty_dag,
        )

    @pytest.mark.vcr
    def test_empty_execute(
        self,
        test_empty_dag: DAG,
        empty_operator: ValidateGTFSToGCSOperator,
        empty_execution_date: datetime,
        empty_source_path: str,
        gcs_hook: GCSHook,
    ):
        empty_operator.run(
            start_date=empty_execution_date - timedelta(days=1),
            end_date=empty_execution_date,
            ignore_first_depends_on_past=True,
        )

        task = test_empty_dag.get_task("validate_gtfs_to_gcs_calendar_dates_empty")
        task_instance = TaskInstance(task, execution_date=empty_execution_date)
        xcom_value = task_instance.xcom_pull()
        assert xcom_value == {
            "dt": "2025-11-13",
            "ts": "2025-11-13T03:02:04.189504+00:00",
            "destination_path": os.path.join(
                os.environ.get("CALITP_BUCKET__GTFS_SCHEDULE_VALIDATION_HOURLY"),
                "validation_notices",
                "dt=2025-11-13",
                "ts=2025-11-13T03:02:04.189504+00:00",
                "base64_url=aHR0cHM6Ly93d3cuaXBzLXN5c3RlbXMuY29tL0dURlMvU2NoZWR1bGUvMjc=",
                "validation_notices_v5-0-0.jsonl.gz",
            ),
            "results_path": os.path.join(
                os.environ.get("CALITP_BUCKET__GTFS_SCHEDULE_VALIDATION_HOURLY"),
                "validation_job_results",
                "dt=2025-11-13",
                "ts=2025-11-13T03:02:04.189504+00:00",
                "aHR0cHM6Ly93d3cuaXBzLXN5c3RlbXMuY29tL0dURlMvU2NoZWR1bGUvMjc=.jsonl",
            ),
        }

        compressed_notices = gcs_hook.exists(
            bucket_name=os.environ.get(
                "CALITP_BUCKET__GTFS_SCHEDULE_VALIDATION_HOURLY"
            ).replace("gs://", ""),
            object_name="validation_notices/dt=2025-11-13/ts=2025-11-13T03:02:04.189504+00:00/base64_url=aHR0cHM6Ly93d3cuaXBzLXN5c3RlbXMuY29tL0dURlMvU2NoZWR1bGUvMjc=/validation_notices_v5-0-0.jsonl.gz",
        )
        assert not compressed_notices

        unparsed_results = gcs_hook.download(
            bucket_name=os.environ.get(
                "CALITP_BUCKET__GTFS_SCHEDULE_VALIDATION_HOURLY"
            ).replace("gs://", ""),
            object_name="validation_job_results/dt=2025-11-13/ts=2025-11-13T03:02:04.189504+00:00/aHR0cHM6Ly93d3cuaXBzLXN5c3RlbXMuY29tL0dURlMvU2NoZWR1bGUvMjc=.jsonl",
        )
        results = json.loads(unparsed_results)
        assert results == {
            "validation": {
                "filename": "validation_notices_v5-0-0.jsonl.gz",
                "system_errors": {"notices": []},
                "validator_version": "v5.0.0",
                "extract_config": {
                    "auth_headers": {},
                    "auth_query_params": {},
                    "computed": False,
                    "extracted_at": "2025-11-12T02:00:00+00:00",
                    "feed_type": "schedule",
                    "name": "Fric and Frac Schedule",
                    "schedule_url_for_validation": None,
                    "url": "https://www.ips-systems.com/GTFS/Schedule/27",
                },
                "ts": "2025-11-13T03:02:04.189504+00:00",
            },
            "extract": {
                "filename": "schedule-27.zip",
                "ts": "2025-11-13T03:02:04.189504+00:00",
                "config": {
                    "auth_headers": {},
                    "auth_query_params": {},
                    "computed": False,
                    "extracted_at": "2025-11-12T02:00:00+00:00",
                    "feed_type": "schedule",
                    "name": "Fric and Frac Schedule",
                    "schedule_url_for_validation": None,
                    "url": "https://www.ips-systems.com/GTFS/Schedule/27",
                },
                "response_code": 200,
                "response_headers": {
                    "Content-Type": "application/zip",
                    "Content-Disposition": "attachment; filename=schedule-27.zip",
                },
                "reconstructed": False,
            },
            "success": True,
            "exception": None,
        }

        metadata = gcs_hook.get_metadata(
            bucket_name=os.environ.get(
                "CALITP_BUCKET__GTFS_SCHEDULE_VALIDATION_HOURLY"
            ).replace("gs://", ""),
            object_name="validation_job_results/dt=2025-11-13/ts=2025-11-13T03:02:04.189504+00:00/aHR0cHM6Ly93d3cuaXBzLXN5c3RlbXMuY29tL0dURlMvU2NoZWR1bGUvMjc=.jsonl",
        )
        assert json.loads(metadata["PARTITIONED_ARTIFACT_METADATA"]) == {
            "filename": "results.jsonl",
            "ts": "2025-11-13T03:02:04.189504+00:00",
        }
