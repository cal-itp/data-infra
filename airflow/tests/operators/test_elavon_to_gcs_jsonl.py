import gzip
import json
from datetime import datetime, timedelta, timezone

import dags.parse_elavon.elavon_to_gcs_jsonl as elavon_parser  # noqa: E402
import pendulum
import pytest
from dags.parse_elavon.elavon_to_gcs_jsonl import (  # noqa: E402
    process_elavon_data_to_jsonl,
)
from freezegun import freeze_time

from airflow.models.dag import DAG  # noqa: E402
from airflow.operators.python import PythonOperator  # noqa: E402
from airflow.providers.google.cloud.hooks.gcs import GCSHook  # noqa: E402


class TestElavonParseAudit:
    @pytest.fixture
    def execution_date(self):
        return datetime(2026, 11, 6, tzinfo=timezone.utc)

    @pytest.fixture
    def test_dag(self, execution_date):
        return DAG(
            "test_elavon_parse",
            default_args={
                "owner": "airflow",
                "start_date": execution_date,
            },
            schedule=timedelta(days=1),
        )

    @pytest.fixture
    def operator(self, test_dag):
        return PythonOperator(
            task_id="parse_elavon",
            python_callable=process_elavon_data_to_jsonl,
            dag=test_dag,
        )

    @freeze_time("2026-11-06 12:00:00", tz_offset=0)
    @pytest.mark.vcr
    def test_execute(self, operator, execution_date, monkeypatch):
        monkeypatch.setattr(
            elavon_parser,
            "CALITP_BUCKET__ELAVON_RAW",
            "gs://calitp-staging-pytest/elavon/raw",
        )

        dt = "2026-11-06"

        with pendulum.test_local_timezone(pendulum.timezone("UTC")):
            operator.run(
                start_date=execution_date,
                end_date=execution_date + timedelta(days=1),
                ignore_first_depends_on_past=True,
            )

        hook = GCSHook()
        bucket = "calitp-staging-pytest"

        # Find the parsed output from this synthetic input.
        parsed_path = (
            "transactions/"
            f"dt={dt}/"
            "execution_ts=2026-11-06T12:00:00+00:00/"
            "elavon-test.jsonl.gz"
        )

        compressed = hook.download(
            bucket_name=bucket,
            object_name=parsed_path,
        )
        records = [
            json.loads(line) for line in gzip.decompress(compressed).splitlines()
        ]

        assert records == [
            {
                "transaction_date": "2026-11-01",
                "amount": "10.00",
                "reference": "TEST-001",
            },
            {
                "transaction_date": "2026-11-02",
                "amount": "20.00",
                "reference": "TEST-002",
            },
        ]

        # Find the corresponding audit record.
        audit_path = (
            "elavon_parse_job_results/"
            f"dt={dt}/"
            "execution_ts=2026-11-06T12:00:00+00:00/"
            "elavon-test.jsonl"
        )

        audit = json.loads(
            hook.download(
                bucket_name=bucket,
                object_name=audit_path,
            )
        )

        assert audit["raw"]["filename"] == "elavon-test.zip"
        assert audit["raw"]["path"] == "elavon/raw/elavon-test.zip"
        assert audit["parsed"]["filename"] == "elavon-test.jsonl.gz"
        assert audit["parsed"]["path"] == parsed_path
        assert audit["parsed"]["size"] == len(compressed)
        assert "agency" not in audit["raw"]
        assert "agency" not in audit["parsed"]
