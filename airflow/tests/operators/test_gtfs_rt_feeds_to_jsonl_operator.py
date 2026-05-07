import gzip
import json
import os
from datetime import datetime, timedelta, timezone

import pytest
from operators.gtfs_rt_feeds_to_jsonl_operator import GTFSRTFeedsToJSONLOperator

from airflow.models.dag import DAG
from airflow.models.taskinstance import TaskInstance
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class TestGTFSRTFeedsToJSONLOperator:
    @pytest.fixture
    def execution_date(self) -> datetime:
        return datetime.fromisoformat("2026-05-01").replace(tzinfo=timezone.utc)

    @pytest.fixture
    def gcs_hook(self) -> GCSHook:
        return GCSHook()

    @pytest.fixture
    def source_paths(self) -> list[str]:
        return [
            os.path.join(
                "service_alerts",
                "dt=2026-05-01",
                "hour=2026-05-01T00:00:00+00:00",
                "ts=2026-05-01T00:00:00+00:00",
                "base64_url=aHR0cDovL2d0ZnMuYmlnYmx1ZWJ1cy5jb20vYWxlcnRzLmJpbg==",
                "feed",
            ),
            os.path.join(
                "service_alerts",
                "dt=2026-05-01",
                "hour=2026-05-01T00:00:00+00:00",
                "ts=2026-05-01T00:00:20+00:00",
                "base64_url=aHR0cDovL2d0ZnMuYmlnYmx1ZWJ1cy5jb20vYWxlcnRzLmJpbg==",
                "feed",
            ),
        ]

    @pytest.fixture
    def destination_path(self) -> str:
        return os.path.join(
            "service_alerts",
            "dt=2026-05-01",
            "hour=2026-05-01T00:00:00+00:00",
            "base64_url=aHR0cDovL2d0ZnMuYmlnYmx1ZWJ1cy5jb20vYWxlcnRzLmJpbg==",
            "service_alerts_aHR0cDovL2d0ZnMuYmlnYmx1ZWJ1cy5jb20vYWxlcnRzLmJpbg==.jsonl.gz",
        )

    @pytest.fixture
    def results_path(self) -> str:
        return os.path.join(
            "service_alerts_outcomes",
            "dt=2026-05-01",
            "hour=2026-05-01T00:00:00+00:00",
            "service_alerts_aHR0cDovL2d0ZnMuYmlnYmx1ZWJ1cy5jb20vYWxlcnRzLmJpbg==.jsonl",
        )

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
        source_paths: list[str],
        destination_path: str,
        results_path: str,
    ) -> GTFSRTFeedsToJSONLOperator:
        return GTFSRTFeedsToJSONLOperator(
            task_id="convert_to_jsonl",
            source_bucket=os.environ.get("CALITP_BUCKET__GTFS_RT_RAW"),
            source_paths=source_paths,
            destination_bucket=os.environ.get("CALITP_BUCKET__GTFS_RT_PARSED"),
            destination_path=destination_path,
            results_path=results_path,
            gcp_conn_id="google_cloud_default",
            dag=test_dag,
        )

    @pytest.fixture
    def feed_path(self) -> str:
        return os.path.realpath(
            os.path.join(
                os.path.dirname(__file__), "../fixtures/feeds/service_alerts.pb"
            )
        )

    @pytest.fixture
    def feed_2_path(self) -> str:
        return os.path.realpath(
            os.path.join(
                os.path.dirname(__file__), "../fixtures/feeds/service_alerts_2.pb"
            )
        )

    @pytest.fixture
    def feed_data(self, feed_path: str) -> bytes:
        with open(feed_path, "rb") as file:
            return file.read()

    @pytest.fixture
    def feed_2_data(self, feed_2_path: str) -> bytes:
        with open(feed_2_path, "rb") as file:
            return file.read()

    @pytest.fixture
    def config(self) -> dict:
        return {
            "auth_headers": {},
            "auth_query_params": {},
            "computed": False,
            "extracted_at": "2026-04-30T03:00:00+00:00",
            "feed_type": "service_alerts",
            "name": "Big Blue Bus Alerts",
            "schedule_url_for_validation": "https://www.bigbluebus.com/gtfs/current.zip",
            "url": "http://gtfs.bigbluebus.com/alerts.bin",
        }

    @pytest.fixture
    def feed_metadata(self, config) -> dict:
        return {
            "filename": "feed",
            "ts": "2026-05-01T00:00:00+00:00",
            "config": config,
            "response_code": 200,
            "response_headers": {
                "Etag": 'W/"33f2f157fdd8dc1:0"',
                "Last-Modified": "Thu, 30 Apr 2026 23:59:12 GMT",
                "Content-Type": "application/octet-stream",
                "Content-Length": "3243",
                "Cache-Control": "max-age=1, public",
                "Expires": "Fri, 01 May 2026 00:00:01 GMT",
                "Date": "Fri, 01 May 2026 00:00:00 GMT",
                "Set-Cookie": "visid_incap_3100510=gCQQgTAxQB6FYDvzr3I4KADt82kAAAAAQUIPAAAAAABwXYZSgt/TAhxgv8UhGn8g; expires=Fri, 30 Apr 2027 06:20:18 GMT; HttpOnly; path=/; Domain=.bigbluebus.com, incap_ses_102_3100510=ibA1XHJi22nKwzFspGBqAQDt82kAAAAAL+Ojsz2yTHBaVT2OW2NU4A==; path=/; Domain=.bigbluebus.com",
                "X-CDN": "Imperva",
                "X-Iinfo": "45-185730431-0 0cNN RT(1777593601659 0) q(0 -1 -1 0) r(0 -1)",
            },
        }

    @pytest.fixture
    def feed_2_metadata(self, config) -> dict:
        return {
            "filename": "feed",
            "ts": "2026-05-01T00:00:20+00:00",
            "config": config,
            "response_code": 200,
            "response_headers": {
                "Etag": 'W/"dcab3a63fdd8dc1:0"',
                "Last-Modified": "Thu, 30 Apr 2026 23:59:31 GMT",
                "Content-Type": "application/octet-stream",
                "Content-Length": "3243",
                "Cache-Control": "max-age=1, public",
                "Expires": "Fri, 01 May 2026 00:00:21 GMT",
                "Date": "Fri, 01 May 2026 00:00:20 GMT",
                "Set-Cookie": "visid_incap_3100510=vTzzF91uSDa76LYpQzbDlhTt82kAAAAAQUIPAAAAAABhjBZO2tbDIkBUZDpoZkzC; expires=Fri, 30 Apr 2027 06:47:07 GMT; HttpOnly; path=/; Domain=.bigbluebus.com, incap_ses_92_3100510=pel8dmNG3ThEro6vr9lGARTt82kAAAAAl79iOoA9SMw5l44sknDtjg==; path=/; Domain=.bigbluebus.com",
                "X-CDN": "Imperva",
                "X-Iinfo": "45-210525617-0 0cNN RT(1777593621033 0) q(0 -1 -1 0) r(1 -1)",
            },
        }

    @pytest.fixture
    def parsed_feed_path(self) -> str:
        return os.path.realpath(
            os.path.join(
                os.path.dirname(__file__), "..", "fixtures", "service_alerts.jsonl.gz"
            )
        )

    @pytest.fixture
    def compressed_parsed_feed_data(self, parsed_feed_path: str) -> bytes:
        with open(parsed_feed_path, "rb") as file:
            return file.read()

    @pytest.fixture
    def decompressed_parsed_feed_data(self, compressed_parsed_feed_data: bytes) -> str:
        return gzip.decompress(compressed_parsed_feed_data)

    @pytest.fixture
    def parsed_feed_data(self, decompressed_parsed_feed_data: str) -> list[dict]:
        return [
            json.loads(line)
            for line in decompressed_parsed_feed_data.strip().splitlines()
        ]

    @pytest.fixture
    def parsed_report_path(self) -> str:
        return os.path.realpath(
            os.path.join(
                os.path.dirname(__file__),
                "..",
                "fixtures",
                "service_alerts_outcomes.jsonl",
            )
        )

    @pytest.fixture
    def parsed_report_data(self, parsed_report_path: str) -> list[dict]:
        with open(parsed_report_path) as file:
            return [json.loads(line) for line in file.read().strip().splitlines()]

    @pytest.mark.vcr
    def test_execute(
        self,
        test_dag: DAG,
        operator: GTFSRTFeedsToJSONLOperator,
        execution_date: datetime,
        source_paths: str,
        destination_path: str,
        results_path: str,
        feed_data: bytes,
        feed_2_data: bytes,
        feed_metadata: bytes,
        feed_2_metadata: bytes,
        parsed_feed_data: list[dict],
        parsed_report_data: list[dict],
        gcs_hook: GCSHook,
    ):
        gcs_hook.upload(
            bucket_name=os.environ.get("CALITP_BUCKET__GTFS_RT_RAW").removeprefix(
                "gs://"
            ),
            object_name=source_paths[0],
            data=feed_data,
            metadata={
                "PARTITIONED_ARTIFACT_METADATA": json.dumps(
                    feed_metadata, separators=(",", ":")
                )
            },
        )

        gcs_hook.upload(
            bucket_name=os.environ.get("CALITP_BUCKET__GTFS_RT_RAW").removeprefix(
                "gs://"
            ),
            object_name=source_paths[1],
            data=feed_2_data,
            metadata={
                "PARTITIONED_ARTIFACT_METADATA": json.dumps(
                    feed_2_metadata, separators=(",", ":")
                )
            },
        )

        operator.run(
            start_date=execution_date,
            end_date=execution_date + timedelta(days=1),
            ignore_first_depends_on_past=True,
        )

        task = test_dag.get_task("convert_to_jsonl")
        task_instance = TaskInstance(task, execution_date=execution_date)
        xcom_value = task_instance.xcom_pull()
        assert xcom_value == {
            "destination_path": os.path.join(
                "service_alerts",
                "dt=2026-05-01",
                "hour=2026-05-01T00:00:00+00:00",
                "base64_url=aHR0cDovL2d0ZnMuYmlnYmx1ZWJ1cy5jb20vYWxlcnRzLmJpbg==",
                "service_alerts_aHR0cDovL2d0ZnMuYmlnYmx1ZWJ1cy5jb20vYWxlcnRzLmJpbg==.jsonl.gz",
            ),
            "results_path": os.path.join(
                "service_alerts_outcomes",
                "dt=2026-05-01",
                "hour=2026-05-01T00:00:00+00:00",
                "service_alerts_aHR0cDovL2d0ZnMuYmlnYmx1ZWJ1cy5jb20vYWxlcnRzLmJpbg==.jsonl",
            ),
        }

        compressed_output = gcs_hook.download(
            bucket_name=os.environ.get("CALITP_BUCKET__GTFS_RT_PARSED").replace(
                "gs://", ""
            ),
            object_name=xcom_value["destination_path"],
        )
        decompressed_output = gzip.decompress(compressed_output)
        output = [json.loads(x) for x in decompressed_output.strip().splitlines()]
        assert output == parsed_feed_data[0:16]

        unparsed_result = gcs_hook.download(
            bucket_name=os.environ.get("CALITP_BUCKET__GTFS_RT_PARSED").replace(
                "gs://", ""
            ),
            object_name=xcom_value["results_path"],
        )
        results = [json.loads(x) for x in unparsed_result.strip().splitlines()]
        assert results == parsed_report_data[0:2]

        metadata = gcs_hook.get_metadata(
            bucket_name=os.environ.get("CALITP_BUCKET__GTFS_RT_PARSED").replace(
                "gs://", ""
            ),
            object_name=xcom_value["results_path"],
        )

        assert json.loads(metadata["PARTITIONED_ARTIFACT_METADATA"]) == {
            "filename": "service_alerts_aHR0cDovL2d0ZnMuYmlnYmx1ZWJ1cy5jb20vYWxlcnRzLmJpbg==.jsonl",
            "step": "parse",
            "feed_type": "service_alerts",
            "hour": "2026-05-01T00:00:00+00:00",
        }
