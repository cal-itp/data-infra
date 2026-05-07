import gzip
import json
import os
from datetime import datetime, timedelta, timezone

import pytest
from operators.validate_gtfs_rt_feeds_to_gcs_operator import (
    ValidateGTFSRTFeedsToGCSOperator,
)

from airflow.models.dag import DAG
from airflow.models.taskinstance import TaskInstance
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class TestValidateGTFSRTFeedsToGCSOperator:
    @pytest.fixture
    def execution_date(self) -> datetime:
        return datetime.fromisoformat("2026-05-01").replace(tzinfo=timezone.utc)

    @pytest.fixture
    def gcs_hook(self) -> GCSHook:
        return GCSHook()

    @pytest.fixture
    def schedule_path(self) -> str:
        return os.path.join(
            "schedule",
            "dt=2026-05-01",
            "ts=2026-05-01T00:00:00+00:00",
            "base64_url=aHR0cHM6Ly93d3cuYmlnYmx1ZWJ1cy5jb20vZ3Rmcy9jdXJyZW50LnppcA==",
            "current.zip",
        )

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
            "service_alerts_validation_notices",
            "dt=2026-05-01",
            "hour=2026-05-01T00:00:00+00:00",
            "base64_url=aHR0cDovL2d0ZnMuYmlnYmx1ZWJ1cy5jb20vYWxlcnRzLmJpbg==",
            "service_alerts_aHR0cDovL2d0ZnMuYmlnYmx1ZWJ1cy5jb20vYWxlcnRzLmJpbg==.jsonl.gz",
        )

    @pytest.fixture
    def results_path(self) -> str:
        return os.path.join(
            "service_alerts_validation_outcomes",
            "dt=2026-05-01",
            "hour=2026-05-01T00:00:00+00:00",
            "service_alerts_aHR0cDovL2d0ZnMuYmlnYmx1ZWJ1cy5jb20vYWxlcnRzLmJpbg==.jsonl",
        )

    @pytest.fixture
    def feed_path(self) -> str:
        return os.path.realpath(
            os.path.join(
                os.path.dirname(__file__), "../fixtures/feeds/service_alerts.pb"
            )
        )

    @pytest.fixture
    def feed_data(self, feed_path: str) -> bytes:
        with open(feed_path, "rb") as file:
            return file.read()

    @pytest.fixture
    def feed_2_path(self) -> str:
        return os.path.realpath(
            os.path.join(
                os.path.dirname(__file__), "../fixtures/feeds/service_alerts_2.pb"
            )
        )

    @pytest.fixture
    def feed_2_data(self, feed_2_path: str) -> bytes:
        with open(feed_2_path, "rb") as file:
            return file.read()

    @pytest.fixture
    def parsed_validation_notices_path(self) -> str:
        return os.path.realpath(
            os.path.join(
                os.path.dirname(__file__),
                "..",
                "fixtures",
                "service_alerts_validation_notices.jsonl",
            )
        )

    @pytest.fixture
    def parsed_validation_notices(
        self, parsed_validation_notices_path: str
    ) -> list[dict]:
        with open(parsed_validation_notices_path) as file:
            return [json.loads(x) for x in file.read().strip().splitlines()]

    @pytest.fixture
    def parsed_validation_outcomes_path(self) -> str:
        return os.path.realpath(
            os.path.join(
                os.path.dirname(__file__),
                "..",
                "fixtures",
                "service_alerts_validation_outcomes.jsonl",
            )
        )

    @pytest.fixture
    def parsed_validation_outcomes(
        self, parsed_validation_outcomes_path: str
    ) -> list[dict]:
        with open(parsed_validation_outcomes_path) as file:
            return [json.loads(x) for x in file.read().strip().splitlines()]

    @pytest.fixture
    def schedule_path(self) -> str:
        return os.path.realpath(
            os.path.join(
                os.path.dirname(__file__), "..", "fixtures", "bigbluebus-schedule.zip"
            )
        )

    @pytest.fixture
    def schedule_data(self, schedule_path: str) -> bytes:
        with open(schedule_path, "rb") as file:
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
    def schedule_metadata(self) -> dict:
        return {
            "reconstructed": False,
            "ts": "2026-05-01T03:00:00.992728+00:00",
            "filename": "current.zip",
            "config": {
                "extracted_at": "2026-05-01T03:00:00+00:00",
                "name": "Big Blue Bus Schedule",
                "url": "https://www.bigbluebus.com/gtfs/current.zip",
                "feed_type": "schedule",
                "schedule_url_for_validation": None,
                "auth_query_params": {},
                "auth_headers": {},
                "computed": False,
            },
            "response_code": 200,
            "response_headers": {
                "Etag": '"2c143315"',
                "Last-Modified": "Wed, 25 Mar 2026 22:01:02 GMT",
                "Content-Type": "application/octet-stream",
                "Content-Length": "5875551",
                "Cache-Control": "max-age=6249, public",
                "Expires": "Fri, 01 May 2026 04:52:26 GMT",
                "Date": "Fri, 01 May 2026 03:08:17 GMT",
                "Set-Cookie": "visid_incap_3100293=/AHafKClSPeqR+vjkalmqCEZ9GkAAAAAQUIPAAAAAADX2vjsHN/xcG1b9TYUyAAj; expires=Fri, 30 Apr 2027 06:47:07 GMT; HttpOnly; path=/; Domain=.bigbluebus.com, incap_ses_92_3100293=tJ6cILpayQ9PZECwr9lGASEZ9GkAAAAAuugu1eRmuBzr3GX0Zr9Zug==; path=/; Domain=.bigbluebus.com",
                "X-CDN": "Imperva",
                "X-Iinfo": "47-254338829-254336822 2CNN RT(1777604898680 47) q(0 1 1 0) r(1 1)",
            },
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
        source_paths: list[str],
        schedule_path: str,
        destination_path: str,
        results_path: str,
    ) -> ValidateGTFSRTFeedsToGCSOperator:
        return ValidateGTFSRTFeedsToGCSOperator(
            task_id="validate_gtfs_rt",
            gcp_conn_id="google_cloud_default",
            source_bucket=os.environ.get("CALITP_BUCKET__GTFS_RT_RAW"),
            source_paths=source_paths,
            schedule_bucket=os.environ.get("CALITP_BUCKET__GTFS_SCHEDULE_RAW"),
            schedule_path=schedule_path,
            destination_bucket=os.environ.get("CALITP_BUCKET__GTFS_RT_VALIDATION"),
            destination_path=destination_path,
            results_path=results_path,
            dag=test_dag,
        )

    @pytest.mark.vcr
    def test_execute(
        self,
        test_dag: DAG,
        operator: ValidateGTFSRTFeedsToGCSOperator,
        execution_date: datetime,
        source_paths: str,
        schedule_path: str,
        feed_data: bytes,
        feed_2_data: bytes,
        feed_metadata: bytes,
        feed_2_metadata: bytes,
        schedule_data: bytes,
        schedule_metadata: bytes,
        parsed_validation_notices: list[dict],
        parsed_validation_outcomes: list[dict],
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

        gcs_hook.upload(
            bucket_name=os.environ.get("CALITP_BUCKET__GTFS_SCHEDULE_RAW").removeprefix(
                "gs://"
            ),
            object_name=schedule_path,
            data=schedule_data,
            metadata={
                "PARTITIONED_ARTIFACT_METADATA": json.dumps(
                    schedule_metadata, separators=(",", ":")
                )
            },
        )

        operator.run(
            start_date=execution_date,
            end_date=execution_date + timedelta(days=1),
            ignore_first_depends_on_past=True,
        )

        task = test_dag.get_task("validate_gtfs_rt")
        task_instance = TaskInstance(task, execution_date=execution_date)
        xcom_value = task_instance.xcom_pull()
        assert xcom_value == {
            "destination_path": os.path.join(
                "service_alerts_validation_notices",
                "dt=2026-05-01",
                "hour=2026-05-01T00:00:00+00:00",
                "base64_url=aHR0cDovL2d0ZnMuYmlnYmx1ZWJ1cy5jb20vYWxlcnRzLmJpbg==",
                "service_alerts_aHR0cDovL2d0ZnMuYmlnYmx1ZWJ1cy5jb20vYWxlcnRzLmJpbg==.jsonl.gz",
            ),
            "results_path": os.path.join(
                "service_alerts_validation_outcomes",
                "dt=2026-05-01",
                "hour=2026-05-01T00:00:00+00:00",
                "service_alerts_aHR0cDovL2d0ZnMuYmlnYmx1ZWJ1cy5jb20vYWxlcnRzLmJpbg==.jsonl",
            ),
        }

        compressed_output = gcs_hook.download(
            bucket_name=os.environ.get("CALITP_BUCKET__GTFS_RT_VALIDATION").replace(
                "gs://", ""
            ),
            object_name=xcom_value["destination_path"],
        )
        decompressed_output = gzip.decompress(compressed_output)
        output = [json.loads(x) for x in decompressed_output.strip().splitlines()]
        assert output == parsed_validation_notices[0:2]

        unparsed_result = gcs_hook.download(
            bucket_name=os.environ.get("CALITP_BUCKET__GTFS_RT_VALIDATION").replace(
                "gs://", ""
            ),
            object_name=xcom_value["results_path"],
        )
        results = [json.loads(x) for x in unparsed_result.strip().splitlines()]
        assert results == parsed_validation_outcomes[0:1]

        metadata = gcs_hook.get_metadata(
            bucket_name=os.environ.get("CALITP_BUCKET__GTFS_RT_VALIDATION").replace(
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
