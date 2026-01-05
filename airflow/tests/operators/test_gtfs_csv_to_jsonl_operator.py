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
    def source_path_fragment(self) -> str:
        return "dt=2025-06-02/ts=2025-06-02T00:00:00+00:00/base64_url=aHR0cDovL2FwcC5tZWNhdHJhbi5jb20vdXJiL3dzL2ZlZWQvYzJsMFpUMXplWFowTzJOc2FXVnVkRDF6Wld4bU8yVjRjR2x5WlQwN2RIbHdaVDFuZEdaek8ydGxlVDAwTWpjd056UTBaVFk0TlRBek9UTXlNREl4TURkak56STBNRFJrTXpZeU5UTTRNekkwWXpJMA=="

    @pytest.fixture
    def destination_path_fragment(self) -> str:
        return "dt=2025-06-02/ts=2025-06-02T00:00:00+00:00/base64_url=aHR0cDovL2FwcC5tZWNhdHJhbi5jb20vdXJiL3dzL2ZlZWQvYzJsMFpUMXplWFowTzJOc2FXVnVkRDF6Wld4bU8yVjRjR2x5WlQwN2RIbHdaVDFuZEdaek8ydGxlVDAwTWpjd056UTBaVFk0TlRBek9UTXlNREl4TURkak56STBNRFJrTXpZeU5UTTRNekkwWXpJMA=="

    @pytest.fixture
    def results_path_fragment(self) -> str:
        return "dt=2025-06-02/ts=2025-06-02T00:00:00+00:00/aHR0cDovL2FwcC5tZWNhdHJhbi5jb20vdXJiL3dzL2ZlZWQvYzJsMFpUMXplWFowTzJOc2FXVnVkRDF6Wld4bU8yVjRjR2x5WlQwN2RIbHdaVDFuZEdaek8ydGxlVDAwTWpjd056UTBaVFk0TlRBek9UTXlNREl4TURkak56STBNRFJrTXpZeU5UTTRNekkwWXpJMA==.jsonl"

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
                },
                {
                    "filename": "feed_info.txt",
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
                    "original_filename": "feed_info.txt",
                },
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
        source_path_fragment: str,
        destination_path_fragment: str,
        results_path_fragment: str,
        unzip_results: dict,
    ) -> GTFSCSVToJSONLOperator:
        return GTFSCSVToJSONLOperator(
            task_id="convert_to_jsonl",
            gcp_conn_id="google_cloud_default",
            unzip_results=unzip_results,
            source_bucket=os.environ.get(
                "CALITP_BUCKET__GTFS_SCHEDULE_UNZIPPED_HOURLY"
            ),
            source_path_fragment=source_path_fragment,
            destination_bucket=os.environ.get(
                "CALITP_BUCKET__GTFS_SCHEDULE_PARSED_HOURLY"
            ),
            destination_path_fragment=destination_path_fragment,
            results_path_fragment=results_path_fragment,
            dag=test_dag,
        )

    @pytest.mark.vcr
    def test_execute(
        self,
        test_dag: DAG,
        operator: GTFSCSVToJSONLOperator,
        execution_date: datetime,
        destination_path_fragment: str,
        results_path_fragment: str,
        gcs_hook: GCSHook,
    ):
        operator.run(
            start_date=execution_date,
            end_date=execution_date + timedelta(days=1),
            ignore_first_depends_on_past=True,
        )

        task = test_dag.get_task("convert_to_jsonl")
        task_instance = TaskInstance(task, execution_date=execution_date)
        xcom_value = task_instance.xcom_pull()
        assert len(xcom_value) == 2  # Converted two extracted files
        assert xcom_value[0] == {
            "results_path": os.path.join(
                "agency.txt_parsing_results",
                "dt=2025-06-02",
                "ts=2025-06-02T00:00:00+00:00",
                "aHR0cDovL2FwcC5tZWNhdHJhbi5jb20vdXJiL3dzL2ZlZWQvYzJsMFpUMXplWFowTzJOc2FXVnVkRDF6Wld4bU8yVjRjR2x5WlQwN2RIbHdaVDFuZEdaek8ydGxlVDAwTWpjd056UTBaVFk0TlRBek9UTXlNREl4TURkak56STBNRFJrTXpZeU5UTTRNekkwWXpJMA==.jsonl",
            ),
            "destination_path": os.path.join(
                "agency",
                "dt=2025-06-02",
                "ts=2025-06-02T00:00:00+00:00",
                "base64_url=aHR0cDovL2FwcC5tZWNhdHJhbi5jb20vdXJiL3dzL2ZlZWQvYzJsMFpUMXplWFowTzJOc2FXVnVkRDF6Wld4bU8yVjRjR2x5WlQwN2RIbHdaVDFuZEdaek8ydGxlVDAwTWpjd056UTBaVFk0TlRBek9UTXlNREl4TURkak56STBNRFJrTXpZeU5UTTRNekkwWXpJMA==",
                "agency.jsonl.gz",
            ),
        }

        assert xcom_value[1] == {
            "results_path": os.path.join(
                "feed_info.txt_parsing_results",
                "dt=2025-06-02",
                "ts=2025-06-02T00:00:00+00:00",
                "aHR0cDovL2FwcC5tZWNhdHJhbi5jb20vdXJiL3dzL2ZlZWQvYzJsMFpUMXplWFowTzJOc2FXVnVkRDF6Wld4bU8yVjRjR2x5WlQwN2RIbHdaVDFuZEdaek8ydGxlVDAwTWpjd056UTBaVFk0TlRBek9UTXlNREl4TURkak56STBNRFJrTXpZeU5UTTRNekkwWXpJMA==.jsonl",
            ),
            "destination_path": os.path.join(
                "feed_info",
                "dt=2025-06-02",
                "ts=2025-06-02T00:00:00+00:00",
                "base64_url=aHR0cDovL2FwcC5tZWNhdHJhbi5jb20vdXJiL3dzL2ZlZWQvYzJsMFpUMXplWFowTzJOc2FXVnVkRDF6Wld4bU8yVjRjR2x5WlQwN2RIbHdaVDFuZEdaek8ydGxlVDAwTWpjd056UTBaVFk0TlRBek9UTXlNREl4TURkak56STBNRFJrTXpZeU5UTTRNekkwWXpJMA==",
                "feed_info.jsonl.gz",
            ),
        }

        # Validate the first converted file agency.txt
        compressed_result = gcs_hook.download(
            bucket_name=os.environ.get(
                "CALITP_BUCKET__GTFS_SCHEDULE_PARSED_HOURLY"
            ).replace("gs://", ""),
            object_name=os.path.join(
                "agency", destination_path_fragment, "agency.jsonl.gz"
            ),
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

        metadata = gcs_hook.get_metadata(
            bucket_name=os.environ.get(
                "CALITP_BUCKET__GTFS_SCHEDULE_PARSED_HOURLY"
            ).replace("gs://", ""),
            object_name=os.path.join(
                "agency", destination_path_fragment, "agency.jsonl.gz"
            ),
        )
        assert json.loads(metadata["PARTITIONED_ARTIFACT_METADATA"]) == {
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
        }

        unparsed_results = gcs_hook.download(
            bucket_name=os.environ.get(
                "CALITP_BUCKET__GTFS_SCHEDULE_PARSED_HOURLY"
            ).replace("gs://", ""),
            object_name=os.path.join(
                "agency.txt_parsing_results", results_path_fragment
            ),
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

        metadata = gcs_hook.get_metadata(
            bucket_name=os.environ.get(
                "CALITP_BUCKET__GTFS_SCHEDULE_PARSED_HOURLY"
            ).replace("gs://", ""),
            object_name=os.path.join(
                "agency.txt_parsing_results", results_path_fragment
            ),
        )
        assert json.loads(metadata["PARTITIONED_ARTIFACT_METADATA"]) == {
            "filename": "results.jsonl",
            "ts": "2025-06-03T00:00:00+00:00",
        }

        # Validate the second converted file feed_info.txt
        compressed_result = gcs_hook.download(
            bucket_name=os.environ.get(
                "CALITP_BUCKET__GTFS_SCHEDULE_PARSED_HOURLY"
            ).replace("gs://", ""),
            object_name=os.path.join(
                "feed_info", destination_path_fragment, "feed_info.jsonl.gz"
            ),
        )
        decompressed_result = gzip.decompress(compressed_result)
        result = [json.loads(x) for x in decompressed_result.splitlines()]
        assert list(result)[0] == {
            "_line_number": 1,
            "feed_contact_email": "marcy@mjcaction.com",
            "feed_contact_url": "https://www.mecatran.com/",
            "feed_end_date": "20260831",
            "feed_lang": "en",
            "feed_publisher_name": "Transnnovation",
            "feed_publisher_url": "http://www.mjcaction.com/",
            "feed_start_date": "20250401",
            "feed_version": "2025-04-26T14:04:39Z",
        }

        metadata = gcs_hook.get_metadata(
            bucket_name=os.environ.get(
                "CALITP_BUCKET__GTFS_SCHEDULE_PARSED_HOURLY"
            ).replace("gs://", ""),
            object_name=os.path.join(
                "feed_info", destination_path_fragment, "feed_info.jsonl.gz"
            ),
        )
        assert json.loads(metadata["PARTITIONED_ARTIFACT_METADATA"]) == {
            "filename": "feed_info.jsonl.gz",
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
            "gtfs_filename": "feed_info",
            "csv_dialect": "excel",
            "num_lines": 1,
        }

        unparsed_results = gcs_hook.download(
            bucket_name=os.environ.get(
                "CALITP_BUCKET__GTFS_SCHEDULE_PARSED_HOURLY"
            ).replace("gs://", ""),
            object_name=os.path.join(
                "feed_info.txt_parsing_results", results_path_fragment
            ),
        )
        results = json.loads(unparsed_results)
        assert results == {
            "success": True,
            "exception": None,
            "feed_file": {
                "filename": "feed_info.txt",
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
                "original_filename": "feed_info.txt",
            },
            "fields": [
                "feed_publisher_name",
                "feed_publisher_url",
                "feed_contact_email",
                "feed_contact_url",
                "feed_lang",
                "feed_start_date",
                "feed_end_date",
                "feed_version",
            ],
            "parsed_file": {
                "filename": "feed_info.jsonl.gz",
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
                "gtfs_filename": "feed_info",
                "csv_dialect": "excel",
                "num_lines": 1,
            },
        }

        metadata = gcs_hook.get_metadata(
            bucket_name=os.environ.get(
                "CALITP_BUCKET__GTFS_SCHEDULE_PARSED_HOURLY"
            ).replace("gs://", ""),
            object_name=os.path.join(
                "feed_info.txt_parsing_results", results_path_fragment
            ),
        )
        assert json.loads(metadata["PARTITIONED_ARTIFACT_METADATA"]) == {
            "filename": "results.jsonl",
            "ts": "2025-06-03T00:00:00+00:00",
        }
