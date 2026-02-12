import json
import os
from csv import DictReader
from datetime import datetime, timedelta, timezone
from io import StringIO

import pytest
from operators.unzip_gtfs_to_gcs_operator import UnzipGTFSToGCSOperator

from airflow.models.dag import DAG
from airflow.models.taskinstance import TaskInstance
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class TestUnzipGTFSToGCSOperator:
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
    def source_path(self) -> str:
        return "schedule/dt=2025-06-02/ts=2025-06-02T00:00:00+00:00/base64_url=aHR0cDovL2FwcC5tZWNhdHJhbi5jb20vdXJiL3dzL2ZlZWQvYzJsMFpUMXplWFowTzJOc2FXVnVkRDF6Wld4bU8yVjRjR2x5WlQwN2RIbHdaVDFuZEdaek8ydGxlVDAwTWpjd056UTBaVFk0TlRBek9UTXlNREl4TURkak56STBNRFJrTXpZeU5UTTRNekkwWXpJMA==/gtfs.zip"

    @pytest.fixture
    def destination_path_fragment(self) -> str:
        return "dt=2025-06-02/ts=2025-06-02T00:00:00+00:00/base64_url=aHR0cDovL2FwcC5tZWNhdHJhbi5jb20vdXJiL3dzL2ZlZWQvYzJsMFpUMXplWFowTzJOc2FXVnVkRDF6Wld4bU8yVjRjR2x5WlQwN2RIbHdaVDFuZEdaek8ydGxlVDAwTWpjd056UTBaVFk0TlRBek9UTXlNREl4TURkak56STBNRFJrTXpZeU5UTTRNekkwWXpJMA=="

    @pytest.fixture
    def results_path(self) -> str:
        return "unzipping_results/dt=2025-06-02/ts=2025-06-02T00:00:00+00:00/aHR0cDovL2FwcC5tZWNhdHJhbi5jb20vdXJiL3dzL2ZlZWQvYzJsMFpUMXplWFowTzJOc2FXVnVkRDF6Wld4bU8yVjRjR2x5WlQwN2RIbHdaVDFuZEdaek8ydGxlVDAwTWpjd056UTBaVFk0TlRBek9UTXlNREl4TURkak56STBNRFJrTXpZeU5UTTRNekkwWXpJMA==.jsonl"

    @pytest.fixture
    def download_schedule_feed_results(self) -> dict:
        return {
            "backfilled": False,
            "config": {
                "auth_headers": {},
                "auth_query_params": {},
                "computed": False,
                "extracted_at": "2025-11-14T02:00:00+00:00",
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
                    "extracted_at": "2025-06-01T00:00:00+00:00",
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
        source_path: str,
        destination_path_fragment: str,
        results_path: str,
        download_schedule_feed_results: dict,
    ) -> UnzipGTFSToGCSOperator:
        return UnzipGTFSToGCSOperator(
            task_id="unzip_gtfs_to_gcs",
            gcp_conn_id="google_cloud_default",
            dt=execution_date.strftime("%Y-%m-%d"),
            ts=execution_date.isoformat(),
            base64_url=base64_url,
            download_schedule_feed_results=download_schedule_feed_results,
            filenames=["agency.txt", "calendar.txt"],
            source_bucket=os.environ.get("CALITP_BUCKET__GTFS_SCHEDULE_RAW"),
            source_path=source_path,
            destination_bucket=os.environ.get(
                "CALITP_BUCKET__GTFS_SCHEDULE_UNZIPPED_HOURLY"
            ),
            destination_path_fragment=destination_path_fragment,
            results_path=results_path,
            dag=test_dag,
        )

    @pytest.mark.vcr
    def test_execute(
        self,
        test_dag: DAG,
        operator: UnzipGTFSToGCSOperator,
        execution_date: datetime,
        destination_path_fragment: str,
        results_path: str,
        gcs_hook: GCSHook,
    ):
        operator.run(
            start_date=execution_date,
            end_date=execution_date + timedelta(days=1),
            ignore_first_depends_on_past=True,
        )

        task = test_dag.get_task("unzip_gtfs_to_gcs")
        task_instance = TaskInstance(task, execution_date=execution_date)
        xcom_value = task_instance.xcom_pull()
        assert xcom_value == {
            "dt": "2025-06-02",
            "ts": "2025-06-02T00:00:00+00:00",
            "base64_url": "aHR0cDovL2FwcC5tZWNhdHJhbi5jb20vdXJiL3dzL2ZlZWQvYzJsMFpUMXplWFowTzJOc2FXVnVkRDF6Wld4bU8yVjRjR2x5WlQwN2RIbHdaVDFuZEdaek8ydGxlVDAwTWpjd056UTBaVFk0TlRBek9UTXlNREl4TURkak56STBNRFJrTXpZeU5UTTRNekkwWXpJMA==",
            "results_path": os.path.join(
                "unzipping_results",
                "dt=2025-06-02",
                "ts=2025-06-02T00:00:00+00:00",
                "aHR0cDovL2FwcC5tZWNhdHJhbi5jb20vdXJiL3dzL2ZlZWQvYzJsMFpUMXplWFowTzJOc2FXVnVkRDF6Wld4bU8yVjRjR2x5WlQwN2RIbHdaVDFuZEdaek8ydGxlVDAwTWpjd056UTBaVFk0TlRBek9UTXlNREl4TURkak56STBNRFJrTXpZeU5UTTRNekkwWXpJMA==.jsonl",
            ),
            "destination_path_fragment": os.path.join(
                "dt=2025-06-02",
                "ts=2025-06-02T00:00:00+00:00",
                "base64_url=aHR0cDovL2FwcC5tZWNhdHJhbi5jb20vdXJiL3dzL2ZlZWQvYzJsMFpUMXplWFowTzJOc2FXVnVkRDF6Wld4bU8yVjRjR2x5WlQwN2RIbHdaVDFuZEdaek8ydGxlVDAwTWpjd056UTBaVFk0TlRBek9UTXlNREl4TURkak56STBNRFJrTXpZeU5UTTRNekkwWXpJMA==",
            ),
            "unzip_results": {
                "exception": None,
                "extract": {
                    "config": {
                        "auth_headers": {},
                        "auth_query_params": {},
                        "computed": False,
                        "extracted_at": "2025-06-01T00:00:00+00:00",
                        "feed_type": "schedule",
                        "name": "Santa Ynez Mecatran Schedule",
                        "schedule_url_for_validation": None,
                        "url": "http://app.mecatran.com/urb/ws/feed/c2l0ZT1zeXZ0O2NsaWVudD1zZWxmO2V4cGlyZT07dHlwZT1ndGZzO2tleT00MjcwNzQ0ZTY4NTAzOTMyMDIxMDdjNzI0MDRkMzYyNTM4MzI0YzI0",
                    },
                    "filename": "gtfs.zip",
                    "reconstructed": False,
                    "response_code": 200,
                    "response_headers": {
                        "Content-Disposition": "attachment; filename=gtfs.zip",
                        "Content-Type": "application/zip",
                    },
                    "ts": "2025-06-02T00:00:00+00:00",
                },
                "extracted_files": [
                    {
                        "extract_config": {
                            "auth_headers": {},
                            "auth_query_params": {},
                            "computed": False,
                            "extracted_at": "2025-06-01T00:00:00+00:00",
                            "feed_type": "schedule",
                            "name": "Santa Ynez Mecatran Schedule",
                            "schedule_url_for_validation": None,
                            "url": "http://app.mecatran.com/urb/ws/feed/c2l0ZT1zeXZ0O2NsaWVudD1zZWxmO2V4cGlyZT07dHlwZT1ndGZzO2tleT00MjcwNzQ0ZTY4NTAzOTMyMDIxMDdjNzI0MDRkMzYyNTM4MzI0YzI0",
                        },
                        "filename": "agency.txt",
                        "original_filename": "agency.txt",
                        "ts": "2025-06-02T00:00:00+00:00",
                    },
                    {
                        "extract_config": {
                            "auth_headers": {},
                            "auth_query_params": {},
                            "computed": False,
                            "extracted_at": "2025-06-01T00:00:00+00:00",
                            "feed_type": "schedule",
                            "name": "Santa Ynez Mecatran Schedule",
                            "schedule_url_for_validation": None,
                            "url": "http://app.mecatran.com/urb/ws/feed/c2l0ZT1zeXZ0O2NsaWVudD1zZWxmO2V4cGlyZT07dHlwZT1ndGZzO2tleT00MjcwNzQ0ZTY4NTAzOTMyMDIxMDdjNzI0MDRkMzYyNTM4MzI0YzI0",
                        },
                        "filename": "calendar.txt",
                        "original_filename": "calendar.txt",
                        "ts": "2025-06-02T00:00:00+00:00",
                    },
                ],
                "success": True,
                "zipfile_dirs": [],
                "zipfile_extract_md5hash": "4f72c84bd3f053ddb929289fa2de7879",
                "zipfile_files": [
                    "agency.txt",
                    "calendar.txt",
                    "calendar_dates.txt",
                    "fare_attributes.txt",
                    "feed_info.txt",
                    "route_directions.txt",
                    "routes.txt",
                    "shapes.txt",
                    "stop_times.txt",
                    "stops.txt",
                    "transfers.txt",
                    "trips.txt",
                ],
            },
        }

        file_content = gcs_hook.download(
            bucket_name=os.environ.get(
                "CALITP_BUCKET__GTFS_SCHEDULE_UNZIPPED_HOURLY"
            ).replace("gs://", ""),
            object_name=f"agency.txt/{destination_path_fragment}/agency.txt",
        )
        reader = DictReader(StringIO(file_content.decode()))
        assert list(reader)[0] == {
            "agency_id": "11214031",
            "agency_name": "Santa Ynez Valley Transit",
            "agency_url": "https://www.syvt.com/489/Santa-Ynez-Valley-Transit",
            "agency_timezone": "America/Los_Angeles",
            "agency_phone": "805-688-5452",
            "agency_lang": "en",
            "agency_fare_url": "https://www.syvt.com/365/Fares",
            "agency_email": "",
            "agency_primary": "1",
        }

        metadata = gcs_hook.get_metadata(
            bucket_name=os.environ.get(
                "CALITP_BUCKET__GTFS_SCHEDULE_UNZIPPED_HOURLY"
            ).replace("gs://", ""),
            object_name=f"agency.txt/{destination_path_fragment}/agency.txt",
        )
        assert json.loads(metadata["PARTITIONED_ARTIFACT_METADATA"]) == {
            "filename": "agency.txt",
            "ts": "2025-06-02T00:00:00+00:00",
            "extract_config": {
                "extracted_at": "2025-06-01T00:00:00+00:00",
                "name": "Santa Ynez Mecatran Schedule",
                "url": "http://app.mecatran.com/urb/ws/feed/c2l0ZT1zeXZ0O2NsaWVudD1zZWxmO2V4cGlyZT07dHlwZT1ndGZzO2tleT00MjcwNzQ0ZTY4NTAzOTMyMDIxMDdjNzI0MDRkMzYyNTM4MzI0YzI0",
                "feed_type": "schedule",
                "schedule_url_for_validation": None,
                "auth_query_params": {},
                "auth_headers": {},
                "computed": False,
            },
            "original_filename": "agency.txt",
        }

        file_content = gcs_hook.download(
            bucket_name=os.environ.get(
                "CALITP_BUCKET__GTFS_SCHEDULE_UNZIPPED_HOURLY"
            ).replace("gs://", ""),
            object_name=f"calendar.txt/{destination_path_fragment}/calendar.txt",
        )
        reader = DictReader(StringIO(file_content.decode()))
        assert list(reader)[0] == {
            "service_id": "11219341",
            "service_name": "mon-sat_ends_50325",
            "start_date": "20250401",
            "end_date": "20250503",
            "sunday": "0",
            "monday": "1",
            "tuesday": "1",
            "wednesday": "1",
            "thursday": "1",
            "friday": "1",
            "saturday": "1",
        }

        metadata = gcs_hook.get_metadata(
            bucket_name=os.environ.get(
                "CALITP_BUCKET__GTFS_SCHEDULE_UNZIPPED_HOURLY"
            ).replace("gs://", ""),
            object_name=f"calendar.txt/{destination_path_fragment}/calendar.txt",
        )
        assert json.loads(metadata["PARTITIONED_ARTIFACT_METADATA"]) == {
            "filename": "calendar.txt",
            "ts": "2025-06-02T00:00:00+00:00",
            "extract_config": {
                "extracted_at": "2025-06-01T00:00:00+00:00",
                "name": "Santa Ynez Mecatran Schedule",
                "url": "http://app.mecatran.com/urb/ws/feed/c2l0ZT1zeXZ0O2NsaWVudD1zZWxmO2V4cGlyZT07dHlwZT1ndGZzO2tleT00MjcwNzQ0ZTY4NTAzOTMyMDIxMDdjNzI0MDRkMzYyNTM4MzI0YzI0",
                "feed_type": "schedule",
                "schedule_url_for_validation": None,
                "auth_query_params": {},
                "auth_headers": {},
                "computed": False,
            },
            "original_filename": "calendar.txt",
        }

        unparsed_results = gcs_hook.download(
            bucket_name=os.environ.get(
                "CALITP_BUCKET__GTFS_SCHEDULE_UNZIPPED_HOURLY"
            ).replace("gs://", ""),
            object_name=results_path,
        )
        results = json.loads(unparsed_results)
        assert results == {
            "success": True,
            "exception": None,
            "extract": {
                "filename": "gtfs.zip",
                "ts": "2025-06-02T00:00:00+00:00",
                "config": {
                    "extracted_at": "2025-06-01T00:00:00+00:00",
                    "name": "Santa Ynez Mecatran Schedule",
                    "url": "http://app.mecatran.com/urb/ws/feed/c2l0ZT1zeXZ0O2NsaWVudD1zZWxmO2V4cGlyZT07dHlwZT1ndGZzO2tleT00MjcwNzQ0ZTY4NTAzOTMyMDIxMDdjNzI0MDRkMzYyNTM4MzI0YzI0",
                    "feed_type": "schedule",
                    "schedule_url_for_validation": None,
                    "auth_query_params": {},
                    "auth_headers": {},
                    "computed": False,
                },
                "response_code": 200,
                "response_headers": results["extract"]["response_headers"]
                | {
                    "Content-Type": "application/zip",
                    "Content-Disposition": "attachment; filename=gtfs.zip",
                },
                "reconstructed": False,
            },
            "zipfile_extract_md5hash": "4f72c84bd3f053ddb929289fa2de7879",
            "zipfile_files": [
                "agency.txt",
                "calendar.txt",
                "calendar_dates.txt",
                "fare_attributes.txt",
                "feed_info.txt",
                "route_directions.txt",
                "routes.txt",
                "shapes.txt",
                "stop_times.txt",
                "stops.txt",
                "transfers.txt",
                "trips.txt",
            ],
            "zipfile_dirs": [],
            "extracted_files": [
                {
                    "filename": "agency.txt",
                    "ts": "2025-06-02T00:00:00+00:00",
                    "extract_config": {
                        "extracted_at": "2025-06-01T00:00:00+00:00",
                        "name": "Santa Ynez Mecatran Schedule",
                        "url": "http://app.mecatran.com/urb/ws/feed/c2l0ZT1zeXZ0O2NsaWVudD1zZWxmO2V4cGlyZT07dHlwZT1ndGZzO2tleT00MjcwNzQ0ZTY4NTAzOTMyMDIxMDdjNzI0MDRkMzYyNTM4MzI0YzI0",
                        "feed_type": "schedule",
                        "schedule_url_for_validation": None,
                        "auth_query_params": {},
                        "auth_headers": {},
                        "computed": False,
                    },
                    "original_filename": "agency.txt",
                },
                {
                    "filename": "calendar.txt",
                    "ts": "2025-06-02T00:00:00+00:00",
                    "extract_config": {
                        "extracted_at": "2025-06-01T00:00:00+00:00",
                        "name": "Santa Ynez Mecatran Schedule",
                        "url": "http://app.mecatran.com/urb/ws/feed/c2l0ZT1zeXZ0O2NsaWVudD1zZWxmO2V4cGlyZT07dHlwZT1ndGZzO2tleT00MjcwNzQ0ZTY4NTAzOTMyMDIxMDdjNzI0MDRkMzYyNTM4MzI0YzI0",
                        "feed_type": "schedule",
                        "schedule_url_for_validation": None,
                        "auth_query_params": {},
                        "auth_headers": {},
                        "computed": False,
                    },
                    "original_filename": "calendar.txt",
                },
            ],
        }

    @pytest.fixture
    def nonexistent_operator(
        self,
        test_dag: DAG,
        execution_date: datetime,
        base64_url: str,
        source_path: str,
        destination_path_fragment: str,
        results_path: str,
        download_schedule_feed_results: dict,
    ) -> UnzipGTFSToGCSOperator:
        return UnzipGTFSToGCSOperator(
            task_id="nonexistent_unzip_gtfs_to_gcs",
            gcp_conn_id="google_cloud_default",
            dt=execution_date.strftime("%Y-%m-%d"),
            ts=execution_date.isoformat(),
            base64_url=base64_url,
            download_schedule_feed_results=download_schedule_feed_results,
            filenames=["areas.txt"],
            source_bucket=os.environ.get("CALITP_BUCKET__GTFS_SCHEDULE_RAW"),
            source_path=source_path,
            destination_bucket=os.environ.get(
                "CALITP_BUCKET__GTFS_SCHEDULE_UNZIPPED_HOURLY"
            ),
            destination_path_fragment=destination_path_fragment,
            results_path=results_path,
            dag=test_dag,
        )

    @pytest.mark.vcr
    def test_nonexistent_execute(
        self,
        test_dag: DAG,
        nonexistent_operator: UnzipGTFSToGCSOperator,
        execution_date: datetime,
        destination_path_fragment: str,
        results_path: str,
        gcs_hook: GCSHook,
    ):
        nonexistent_operator.run(
            start_date=execution_date,
            end_date=execution_date + timedelta(days=1),
            ignore_first_depends_on_past=True,
        )

        task = test_dag.get_task("nonexistent_unzip_gtfs_to_gcs")
        task_instance = TaskInstance(task, execution_date=execution_date)
        xcom_value = task_instance.xcom_pull()
        assert xcom_value == {
            "dt": "2025-06-02",
            "ts": "2025-06-02T00:00:00+00:00",
            "base64_url": "aHR0cDovL2FwcC5tZWNhdHJhbi5jb20vdXJiL3dzL2ZlZWQvYzJsMFpUMXplWFowTzJOc2FXVnVkRDF6Wld4bU8yVjRjR2x5WlQwN2RIbHdaVDFuZEdaek8ydGxlVDAwTWpjd056UTBaVFk0TlRBek9UTXlNREl4TURkak56STBNRFJrTXpZeU5UTTRNekkwWXpJMA==",
            "results_path": os.path.join(
                "unzipping_results",
                "dt=2025-06-02",
                "ts=2025-06-02T00:00:00+00:00",
                "aHR0cDovL2FwcC5tZWNhdHJhbi5jb20vdXJiL3dzL2ZlZWQvYzJsMFpUMXplWFowTzJOc2FXVnVkRDF6Wld4bU8yVjRjR2x5WlQwN2RIbHdaVDFuZEdaek8ydGxlVDAwTWpjd056UTBaVFk0TlRBek9UTXlNREl4TURkak56STBNRFJrTXpZeU5UTTRNekkwWXpJMA==.jsonl",
            ),
            "destination_path_fragment": os.path.join(
                "dt=2025-06-02",
                "ts=2025-06-02T00:00:00+00:00",
                "base64_url=aHR0cDovL2FwcC5tZWNhdHJhbi5jb20vdXJiL3dzL2ZlZWQvYzJsMFpUMXplWFowTzJOc2FXVnVkRDF6Wld4bU8yVjRjR2x5WlQwN2RIbHdaVDFuZEdaek8ydGxlVDAwTWpjd056UTBaVFk0TlRBek9UTXlNREl4TURkak56STBNRFJrTXpZeU5UTTRNekkwWXpJMA==",
            ),
            "unzip_results": {
                "exception": None,
                "extract": {
                    "config": {
                        "auth_headers": {},
                        "auth_query_params": {},
                        "computed": False,
                        "extracted_at": "2025-06-01T00:00:00+00:00",
                        "feed_type": "schedule",
                        "name": "Santa Ynez Mecatran Schedule",
                        "schedule_url_for_validation": None,
                        "url": "http://app.mecatran.com/urb/ws/feed/c2l0ZT1zeXZ0O2NsaWVudD1zZWxmO2V4cGlyZT07dHlwZT1ndGZzO2tleT00MjcwNzQ0ZTY4NTAzOTMyMDIxMDdjNzI0MDRkMzYyNTM4MzI0YzI0",
                    },
                    "filename": "gtfs.zip",
                    "reconstructed": False,
                    "response_code": 200,
                    "response_headers": {
                        "Content-Disposition": "attachment; filename=gtfs.zip",
                        "Content-Type": "application/zip",
                    },
                    "ts": "2025-06-02T00:00:00+00:00",
                },
                "extracted_files": [],
                "success": True,
                "zipfile_dirs": [],
                "zipfile_extract_md5hash": "4f72c84bd3f053ddb929289fa2de7879",
                "zipfile_files": [
                    "agency.txt",
                    "calendar.txt",
                    "calendar_dates.txt",
                    "fare_attributes.txt",
                    "feed_info.txt",
                    "route_directions.txt",
                    "routes.txt",
                    "shapes.txt",
                    "stop_times.txt",
                    "stops.txt",
                    "transfers.txt",
                    "trips.txt",
                ],
            },
        }

        file_content = gcs_hook.exists(
            bucket_name=os.environ.get(
                "CALITP_BUCKET__GTFS_SCHEDULE_UNZIPPED_HOURLY"
            ).replace("gs://", ""),
            object_name=f"areas.txt/{destination_path_fragment}/areas.txt",
        )
        assert not file_content

        unparsed_results = gcs_hook.download(
            bucket_name=os.environ.get(
                "CALITP_BUCKET__GTFS_SCHEDULE_UNZIPPED_HOURLY"
            ).replace("gs://", ""),
            object_name=results_path,
        )
        results = json.loads(unparsed_results)
        assert results == {
            "success": True,
            "exception": None,
            "extract": {
                "filename": "gtfs.zip",
                "ts": "2025-06-02T00:00:00+00:00",
                "config": {
                    "extracted_at": "2025-06-01T00:00:00+00:00",
                    "name": "Santa Ynez Mecatran Schedule",
                    "url": "http://app.mecatran.com/urb/ws/feed/c2l0ZT1zeXZ0O2NsaWVudD1zZWxmO2V4cGlyZT07dHlwZT1ndGZzO2tleT00MjcwNzQ0ZTY4NTAzOTMyMDIxMDdjNzI0MDRkMzYyNTM4MzI0YzI0",
                    "feed_type": "schedule",
                    "schedule_url_for_validation": None,
                    "auth_query_params": {},
                    "auth_headers": {},
                    "computed": False,
                },
                "response_code": 200,
                "response_headers": results["extract"]["response_headers"]
                | {
                    "Content-Type": "application/zip",
                    "Content-Disposition": "attachment; filename=gtfs.zip",
                },
                "reconstructed": False,
            },
            "zipfile_extract_md5hash": "4f72c84bd3f053ddb929289fa2de7879",
            "zipfile_files": [
                "agency.txt",
                "calendar.txt",
                "calendar_dates.txt",
                "fare_attributes.txt",
                "feed_info.txt",
                "route_directions.txt",
                "routes.txt",
                "shapes.txt",
                "stop_times.txt",
                "stops.txt",
                "transfers.txt",
                "trips.txt",
            ],
            "zipfile_dirs": [],
            "extracted_files": [],
        }

    @pytest.fixture
    def empty_execution_date(self) -> datetime:
        return datetime.fromisoformat("2025-11-13").replace(tzinfo=timezone.utc)

    @pytest.fixture
    def empty_base64_url(self) -> str:
        return "aHR0cHM6Ly93d3cuaXBzLXN5c3RlbXMuY29tL0dURlMvU2NoZWR1bGUvMjc="

    @pytest.fixture
    def empty_source_path(self) -> str:
        return "schedule/dt=2025-11-13/ts=2025-11-13T03:02:04.189504+00:00/base64_url=aHR0cHM6Ly93d3cuaXBzLXN5c3RlbXMuY29tL0dURlMvU2NoZWR1bGUvMjc=/schedule-27.zip"

    @pytest.fixture
    def empty_destination_path_fragment(self) -> str:
        return "dt=2025-11-13/ts=2025-11-13T03:02:04.189504+00:00/base64_url=aHR0cHM6Ly93d3cuaXBzLXN5c3RlbXMuY29tL0dURlMvU2NoZWR1bGUvMjc="

    @pytest.fixture
    def empty_results_path(self) -> str:
        return "unzipping_results/dt=2025-11-13/ts=2025-11-13T03:02:04.189504+00:00/aHR0cHM6Ly93d3cuaXBzLXN5c3RlbXMuY29tL0dURlMvU2NoZWR1bGUvMjc=.jsonl"

    @pytest.fixture
    def empty_download_schedule_feed_results(self) -> dict:
        return {
            "backfilled": False,
            "config": {
                "auth_headers": {},
                "auth_query_params": {},
                "computed": False,
                "extracted_at": "2025-11-25T00:00:00+00:00",
                "feed_type": "schedule",
                "name": "Fric and Frac Schedule",
                "schedule_url_for_validation": None,
                "url": "https://www.ips-systems.com/GTFS/Schedule/27",
            },
            "exception": None,
            "extract": {
                "filename": "gtfs.zip",
                "ts": "2025-11-13T00:00:00+00:00",
                "config": {
                    "auth_headers": {},
                    "auth_query_params": {},
                    "computed": False,
                    "extracted_at": "2025-11-25T00:00:00+00:00",
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
    def empty_test_dag(self, empty_execution_date: datetime) -> DAG:
        return DAG(
            "test_dag",
            default_args={
                "owner": "airflow",
                "start_date": empty_execution_date,
                "end_date": empty_execution_date + timedelta(days=1),
            },
            schedule=timedelta(days=1),
        )

    @pytest.fixture
    def empty_operator(
        self,
        empty_test_dag: DAG,
        empty_execution_date: datetime,
        empty_base64_url: str,
        empty_source_path: str,
        empty_destination_path_fragment: str,
        empty_results_path: str,
        empty_download_schedule_feed_results: dict,
    ) -> UnzipGTFSToGCSOperator:
        return UnzipGTFSToGCSOperator(
            task_id="empty_unzip_gtfs_to_gcs",
            gcp_conn_id="google_cloud_default",
            dt=empty_execution_date.strftime("%Y-%m-%d"),
            ts=empty_execution_date.isoformat(),
            base64_url=empty_base64_url,
            download_schedule_feed_results=empty_download_schedule_feed_results,
            filenames=["calendar_dates.txt"],
            source_bucket=os.environ.get("CALITP_BUCKET__GTFS_SCHEDULE_RAW"),
            source_path=empty_source_path,
            destination_bucket=os.environ.get(
                "CALITP_BUCKET__GTFS_SCHEDULE_UNZIPPED_HOURLY"
            ),
            destination_path_fragment=empty_destination_path_fragment,
            results_path=empty_results_path,
            dag=empty_test_dag,
        )

    @pytest.mark.vcr
    def test_empty_execute(
        self,
        empty_test_dag: DAG,
        empty_operator: UnzipGTFSToGCSOperator,
        empty_execution_date: datetime,
        empty_destination_path_fragment: str,
        empty_results_path: str,
        gcs_hook: GCSHook,
    ):
        empty_operator.run(
            start_date=empty_execution_date,
            end_date=empty_execution_date + timedelta(days=1),
            ignore_first_depends_on_past=True,
        )

        task = empty_test_dag.get_task("empty_unzip_gtfs_to_gcs")
        task_instance = TaskInstance(task, execution_date=empty_execution_date)
        xcom_value = task_instance.xcom_pull()
        assert xcom_value == {
            "dt": "2025-11-13",
            "ts": "2025-11-13T00:00:00+00:00",
            "base64_url": "aHR0cHM6Ly93d3cuaXBzLXN5c3RlbXMuY29tL0dURlMvU2NoZWR1bGUvMjc=",
            "results_path": os.path.join(
                "unzipping_results",
                "dt=2025-11-13",
                "ts=2025-11-13T03:02:04.189504+00:00",
                "aHR0cHM6Ly93d3cuaXBzLXN5c3RlbXMuY29tL0dURlMvU2NoZWR1bGUvMjc=.jsonl",
            ),
            "destination_path_fragment": os.path.join(
                "dt=2025-11-13",
                "ts=2025-11-13T03:02:04.189504+00:00",
                "base64_url=aHR0cHM6Ly93d3cuaXBzLXN5c3RlbXMuY29tL0dURlMvU2NoZWR1bGUvMjc=",
            ),
            "unzip_results": {
                "exception": None,
                "extract": {
                    "config": {
                        "auth_headers": {},
                        "auth_query_params": {},
                        "computed": False,
                        "extracted_at": "2025-11-25T00:00:00+00:00",
                        "feed_type": "schedule",
                        "name": "Fric and Frac Schedule",
                        "schedule_url_for_validation": None,
                        "url": "https://www.ips-systems.com/GTFS/Schedule/27",
                    },
                    "filename": "gtfs.zip",
                    "reconstructed": False,
                    "response_code": 200,
                    "response_headers": {
                        "Content-Disposition": "attachment; filename=schedule-27.zip",
                        "Content-Type": "application/zip",
                    },
                    "ts": "2025-11-13T00:00:00+00:00",
                },
                "extracted_files": [
                    {
                        "extract_config": {
                            "auth_headers": {},
                            "auth_query_params": {},
                            "computed": False,
                            "extracted_at": "2025-11-25T00:00:00+00:00",
                            "feed_type": "schedule",
                            "name": "Fric and Frac Schedule",
                            "schedule_url_for_validation": None,
                            "url": "https://www.ips-systems.com/GTFS/Schedule/27",
                        },
                        "filename": "calendar_dates.txt",
                        "original_filename": "calendar_dates.txt",
                        "ts": "2025-11-13T00:00:00+00:00",
                    }
                ],
                "success": True,
                "zipfile_dirs": [],
                "zipfile_extract_md5hash": "833f5a292eed717823acf709b2548a2b",
                "zipfile_files": [
                    "agency.txt",
                    "calendar.txt",
                    "calendar_dates.txt",
                    "feed_info.txt",
                    "routes.txt",
                    "shapes.txt",
                    "stop_times.txt",
                    "stops.txt",
                    "trips.txt",
                ],
            },
        }

        file_content = gcs_hook.download(
            bucket_name=os.environ.get(
                "CALITP_BUCKET__GTFS_SCHEDULE_UNZIPPED_HOURLY"
            ).replace("gs://", ""),
            object_name=os.path.join(
                "calendar_dates.txt",
                empty_destination_path_fragment,
                "calendar_dates.txt",
            ),
        )
        reader = DictReader(StringIO(file_content.decode()))
        assert list(reader) == []

        metadata = gcs_hook.get_metadata(
            bucket_name=os.environ.get(
                "CALITP_BUCKET__GTFS_SCHEDULE_UNZIPPED_HOURLY"
            ).replace("gs://", ""),
            object_name=os.path.join(
                "calendar_dates.txt",
                empty_destination_path_fragment,
                "calendar_dates.txt",
            ),
        )
        assert json.loads(metadata["PARTITIONED_ARTIFACT_METADATA"]) == {
            "filename": "calendar_dates.txt",
            "ts": "2025-11-13T00:00:00+00:00",
            "extract_config": {
                "auth_headers": {},
                "auth_query_params": {},
                "computed": False,
                "extracted_at": "2025-11-25T00:00:00+00:00",
                "feed_type": "schedule",
                "name": "Fric and Frac Schedule",
                "schedule_url_for_validation": None,
                "url": "https://www.ips-systems.com/GTFS/Schedule/27",
            },
            "original_filename": "calendar_dates.txt",
        }

        unparsed_results = gcs_hook.download(
            bucket_name=os.environ.get(
                "CALITP_BUCKET__GTFS_SCHEDULE_UNZIPPED_HOURLY"
            ).replace("gs://", ""),
            object_name=empty_results_path,
        )
        results = json.loads(unparsed_results)
        assert results == {
            "success": True,
            "exception": None,
            "extract": {
                "filename": "gtfs.zip",
                "ts": "2025-11-13T00:00:00+00:00",
                "config": {
                    "auth_headers": {},
                    "auth_query_params": {},
                    "computed": False,
                    "extracted_at": "2025-11-25T00:00:00+00:00",
                    "feed_type": "schedule",
                    "name": "Fric and Frac Schedule",
                    "schedule_url_for_validation": None,
                    "url": "https://www.ips-systems.com/GTFS/Schedule/27",
                },
                "response_code": 200,
                "response_headers": results["extract"]["response_headers"]
                | {
                    "Content-Type": "application/zip",
                    "Content-Disposition": "attachment; filename=schedule-27.zip",
                },
                "reconstructed": False,
            },
            "zipfile_extract_md5hash": "833f5a292eed717823acf709b2548a2b",
            "zipfile_files": [
                "agency.txt",
                "calendar.txt",
                "calendar_dates.txt",
                "feed_info.txt",
                "routes.txt",
                "shapes.txt",
                "stop_times.txt",
                "stops.txt",
                "trips.txt",
            ],
            "zipfile_dirs": [],
            "extracted_files": [
                {
                    "extract_config": {
                        "auth_headers": {},
                        "auth_query_params": {},
                        "computed": False,
                        "extracted_at": "2025-11-25T00:00:00+00:00",
                        "feed_type": "schedule",
                        "name": "Fric and Frac Schedule",
                        "schedule_url_for_validation": None,
                        "url": "https://www.ips-systems.com/GTFS/Schedule/27",
                    },
                    "filename": "calendar_dates.txt",
                    "original_filename": "calendar_dates.txt",
                    "ts": "2025-11-13T00:00:00+00:00",
                }
            ],
        }
