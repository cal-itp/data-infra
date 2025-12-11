import os
from datetime import datetime, timezone

import pytest
from dateutil.relativedelta import relativedelta
from operators.gcs_to_gtfs_download_operator import GCSToGTFSDownloadOperator

from airflow.models.dag import DAG
from airflow.models.taskinstance import TaskInstance


class TestGCSToGTFSDownloadOperator:
    @pytest.fixture
    def execution_date(self) -> datetime:
        return datetime.fromisoformat("2025-06-02").replace(tzinfo=timezone.utc)

    @pytest.fixture
    def test_dag(self, execution_date: datetime) -> DAG:
        return DAG(
            "test_dag",
            default_args={
                "owner": "airflow",
                "start_date": execution_date,
                "end_date": execution_date + relativedelta(days=+1),
            },
            schedule=relativedelta(days=+1),
        )

    @pytest.fixture
    def operator(self, test_dag: DAG) -> GCSToGTFSDownloadOperator:
        return GCSToGTFSDownloadOperator(
            task_id="gcs_to_gtfs_download",
            gcp_conn_id="google_cloud_default",
            source_bucket=os.environ.get("CALITP_BUCKET__GTFS_SCHEDULE_RAW"),
            source_path=os.path.join(
                "download_schedule_feed_results",
                "dt=2025-06-02",
                "ts=2025-06-02T00:00:00+00:00",
                "aHR0cDovL2FwcC5tZWNhdHJhbi5jb20vdXJiL3dzL2ZlZWQvYzJsMFpUMXplWFowTzJOc2FXVnVkRDF6Wld4bU8yVjRjR2x5WlQwN2RIbHdaVDFuZEdaek8ydGxlVDAwTWpjd056UTBaVFk0TlRBek9UTXlNREl4TURkak56STBNRFJrTXpZeU5UTTRNekkwWXpJMA==.jsonl",
            ),
            dag=test_dag,
        )

    @pytest.mark.vcr
    def test_execute(
        self,
        test_dag: DAG,
        operator: GCSToGTFSDownloadOperator,
        execution_date: datetime,
    ):
        operator.run(
            start_date=execution_date,
            end_date=execution_date
            + relativedelta(days=+1)
            - relativedelta(seconds=-1),
            ignore_first_depends_on_past=True,
        )

        task = test_dag.get_task("gcs_to_gtfs_download")
        task_instance = TaskInstance(task, execution_date=execution_date)
        xcom_value = task_instance.xcom_pull()
        assert xcom_value == {
            "base64_url": "aHR0cDovL2FwcC5tZWNhdHJhbi5jb20vdXJiL3dzL2ZlZWQvYzJsMFpUMXplWFowTzJOc2FXVnVkRDF6Wld4bU8yVjRjR2x5WlQwN2RIbHdaVDFuZEdaek8ydGxlVDAwTWpjd056UTBaVFk0TlRBek9UTXlNREl4TURkak56STBNRFJrTXpZeU5UTTRNekkwWXpJMA==",
            "download_schedule_feed_results": {
                "backfilled": False,
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
                        "Connection": "keep-alive",
                        "Content-Disposition": "attachment; filename=gtfs.zip",
                        "Content-Type": "application/zip",
                        "Date": "Tue, 25 Nov 2025 18:44:46 GMT",
                        "Server": "nginx/1.24.0 (Ubuntu)",
                    },
                    "ts": "2025-06-03T00:00:00+00:00",
                },
                "success": True,
            },
            "schedule_feed_path": "schedule/dt=2025-06-02/ts=2025-06-02T00:00:00+00:00/base64_url=aHR0cDovL2FwcC5tZWNhdHJhbi5jb20vdXJiL3dzL2ZlZWQvYzJsMFpUMXplWFowTzJOc2FXVnVkRDF6Wld4bU8yVjRjR2x5WlQwN2RIbHdaVDFuZEdaek8ydGxlVDAwTWpjd056UTBaVFk0TlRBek9UTXlNREl4TURkak56STBNRFJrTXpZeU5UTTRNekkwWXpJMA==/gtfs.zip",
        }
