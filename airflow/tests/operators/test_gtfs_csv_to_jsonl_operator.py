import gzip
import json
import os
from datetime import datetime, timedelta, timezone

import pytest
from operators.gtfs_csv_to_jsonl_operator import GTFSCSVToJSONLOperator

from airflow.models.dag import DAG
from airflow.models.taskinstance import TaskInstance
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class TestGTFSCSVToJSONLOperator:
    @pytest.fixture
    def execution_date(self) -> datetime:
        return datetime.fromisoformat("2025-06-02").replace(tzinfo=timezone.utc)

    @pytest.fixture
    def gcs_hook(self) -> GCSHook:
        return GCSHook()

    @pytest.fixture
    def source_path(self) -> str:
        return "agency.txt/dt=2025-06-02/ts=2025-06-02T00:00:00+00:00/base64_url=aHR0cDovL2FwcC5tZWNhdHJhbi5jb20vdXJiL3dzL2ZlZWQvYzJsMFpUMXplWFowTzJOc2FXVnVkRDF6Wld4bU8yVjRjR2x5WlQwN2RIbHdaVDFuZEdaek8ydGxlVDAwTWpjd056UTBaVFk0TlRBek9UTXlNREl4TURkak56STBNRFJrTXpZeU5UTTRNekkwWXpJMA==/agency.txt"

    @pytest.fixture
    def destination_path(self) -> str:
        return "agency/dt=2025-06-02/ts=2025-06-02T00:00:00+00:00/base64_url=aHR0cDovL2FwcC5tZWNhdHJhbi5jb20vdXJiL3dzL2ZlZWQvYzJsMFpUMXplWFowTzJOc2FXVnVkRDF6Wld4bU8yVjRjR2x5WlQwN2RIbHdaVDFuZEdaek8ydGxlVDAwTWpjd056UTBaVFk0TlRBek9UTXlNREl4TURkak56STBNRFJrTXpZeU5UTTRNekkwWXpJMA==/agency.jsonl.gz"

    @pytest.fixture
    def results_path(self) -> str:
        return "agency.txt_parsing_results/dt=2025-06-02/ts=2025-06-02T00:00:00+00:00/agency.txt_aHR0cDovL2FwcC5tZWNhdHJhbi5jb20vdXJiL3dzL2ZlZWQvYzJsMFpUMXplWFowTzJOc2FXVnVkRDF6Wld4bU8yVjRjR2x5WlQwN2RIbHdaVDFuZEdaek8ydGxlVDAwTWpjd056UTBaVFk0TlRBek9UTXlNREl4TURkak56STBNRFJrTXpZeU5UTTRNekkwWXpJMA==.jsonl"

    @pytest.fixture
    def unzip_results(self) -> dict:
        return {
            "success": True,
            "exception": None,
            "extract": {
                "filename": "gtfs.zip",
                "ts": "2025-06-03T00:00:00+00:00",
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
                "response_headers": {
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
                    "ts": "2025-06-03T00:00:00+00:00",
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
            ],
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
        source_path: str,
        destination_path: str,
        results_path: str,
        unzip_results: dict,
    ) -> GTFSCSVToJSONLOperator:
        return GTFSCSVToJSONLOperator(
            task_id="gtfs_csv_to_jsonl",
            gcp_conn_id="google_cloud_default",
            unzip_results=unzip_results,
            source_bucket=os.environ.get(
                "CALITP_BUCKET__GTFS_SCHEDULE_UNZIPPED_HOURLY"
            ),
            source_path=source_path,
            destination_bucket=os.environ.get(
                "CALITP_BUCKET__GTFS_SCHEDULE_PARSED_HOURLY"
            ),
            destination_path=destination_path,
            results_path=results_path,
            dag=test_dag,
        )

    @pytest.mark.vcr
    def test_execute(
        self,
        test_dag: DAG,
        operator: GTFSCSVToJSONLOperator,
        execution_date: datetime,
        destination_path: str,
        results_path: str,
        gcs_hook: GCSHook,
    ):
        operator.run(
            start_date=execution_date,
            end_date=execution_date + timedelta(days=1),
            ignore_first_depends_on_past=True,
        )

        task = test_dag.get_task("gtfs_csv_to_jsonl")
        task_instance = TaskInstance(task, execution_date=execution_date)
        xcom_value = task_instance.xcom_pull()
        assert xcom_value["results_path"] == os.path.join(
            os.environ.get("CALITP_BUCKET__GTFS_SCHEDULE_PARSED_HOURLY"),
            "agency.txt_parsing_results",
            "dt=2025-06-02",
            "ts=2025-06-02T00:00:00+00:00",
            "agency.txt_aHR0cDovL2FwcC5tZWNhdHJhbi5jb20vdXJiL3dzL2ZlZWQvYzJsMFpUMXplWFowTzJOc2FXVnVkRDF6Wld4bU8yVjRjR2x5WlQwN2RIbHdaVDFuZEdaek8ydGxlVDAwTWpjd056UTBaVFk0TlRBek9UTXlNREl4TURkak56STBNRFJrTXpZeU5UTTRNekkwWXpJMA==.jsonl",
        )
        assert xcom_value["destination_path"] == os.path.join(
            os.environ.get("CALITP_BUCKET__GTFS_SCHEDULE_PARSED_HOURLY"),
            "agency",
            "dt=2025-06-02",
            "ts=2025-06-02T00:00:00+00:00",
            "base64_url=aHR0cDovL2FwcC5tZWNhdHJhbi5jb20vdXJiL3dzL2ZlZWQvYzJsMFpUMXplWFowTzJOc2FXVnVkRDF6Wld4bU8yVjRjR2x5WlQwN2RIbHdaVDFuZEdaek8ydGxlVDAwTWpjd056UTBaVFk0TlRBek9UTXlNREl4TURkak56STBNRFJrTXpZeU5UTTRNekkwWXpJMA==",
            "agency.jsonl.gz",
        )

        compressed_result = gcs_hook.download(
            bucket_name=os.environ.get(
                "CALITP_BUCKET__GTFS_SCHEDULE_PARSED_HOURLY"
            ).replace("gs://", ""),
            object_name=destination_path,
        )
        decompressed_result = gzip.decompress(compressed_result)
        result = [json.loads(x) for x in decompressed_result.splitlines()]
        assert list(result)[0] == {
            "_line_number": 1,
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

        unparsed_results = gcs_hook.download(
            bucket_name=os.environ.get(
                "CALITP_BUCKET__GTFS_SCHEDULE_PARSED_HOURLY"
            ).replace("gs://", ""),
            object_name=results_path,
        )
        results = json.loads(unparsed_results)
        assert results == {
            "success": True,
            "exception": None,
            "feed_file": {
                "filename": "agency.txt",
                "ts": "2025-06-03T00:00:00+00:00",
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
            "fields": [
                "agency_id",
                "agency_name",
                "agency_url",
                "agency_timezone",
                "agency_phone",
                "agency_lang",
                "agency_fare_url",
                "agency_email",
                "agency_primary",
            ],
            "parsed_file": {
                "filename": "agency.jsonl.gz",
                "ts": "2025-06-03T00:00:00+00:00",
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
                "gtfs_filename": "agency",
                "csv_dialect": "excel",
                "num_lines": 1,
            },
        }
