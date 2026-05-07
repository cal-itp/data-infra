import gzip
import json
import os
import sys
import types
from datetime import datetime, timezone
from unittest.mock import MagicMock

import pytest
from operators.validate_tides_to_gcs_operator import ValidateTIDESToGCSOperator

from airflow.models.dag import DAG


class FakeError:
    def __init__(self, type_: str):
        self.type = type_


class FakeTask:
    def __init__(self, errors: list):
        self.errors = errors


class FakeReport:
    def __init__(self, valid: bool, tasks: list):
        self.valid = valid
        self.tasks = tasks


def _frictionless_stub(report) -> types.ModuleType:
    module = types.ModuleType("frictionless")
    module.Resource = lambda **kwargs: MagicMock(**kwargs)
    module.Schema = MagicMock()
    module.Schema.from_descriptor = lambda descriptor: MagicMock()
    module.system = types.SimpleNamespace(trusted=False)
    module.validate = lambda resource: report
    return module


class CapturingGCSHook:
    def __init__(self):
        self.uploads: list[dict] = []

    def upload(self, **kwargs):
        self.uploads.append(kwargs)


class TestValidateTIDESToGCSOperator:
    feed_url = "https://example.org/gtfs-rt/vehicle_positions"
    base64_feed = "aHR0cHM6Ly9leGFtcGxlLm9yZy9ndGZzLXJ0L3ZlaGljbGVfcG9zaXRpb25z"

    @pytest.fixture
    def execution_date(self) -> datetime:
        return datetime.fromisoformat("2026-04-01").replace(tzinfo=timezone.utc)

    @pytest.fixture
    def test_dag(self, execution_date: datetime) -> DAG:
        return DAG(
            "test_dag",
            default_args={
                "owner": "airflow",
                "start_date": execution_date,
                "end_date": execution_date,
            },
            schedule="@daily",
        )

    @pytest.fixture
    def operator(
        self, test_dag: DAG, execution_date: datetime
    ) -> ValidateTIDESToGCSOperator:
        return ValidateTIDESToGCSOperator(
            task_id="vehicle_locations_validate",
            gcp_conn_id="google_cloud_default",
            dt=execution_date.strftime("%Y-%m-%d"),
            ts=execution_date.isoformat(),
            dataset_id="mart_tides",
            table_name="fct_tides_vehicle_locations",
            service_date="2026-03-31",
            gtfs_dataset_key="9edf45e373638700ca420b1e588efdaf",
            feed_name="Beach Cities Transit Vehicle Positions",
            feed_url=self.feed_url,
            schema_url=(
                "https://raw.githubusercontent.com/TIDES-transit/TIDES/main/"
                "spec/vehicle_locations.schema.json"
            ),
            destination_bucket=os.environ.get("CALITP_BUCKET__TIDES_PUBLISH"),
            outcome_path_prefix="validation_outcomes/vehicle_locations",
            dag=test_dag,
        )

    def test_outcome_object_name_is_partitioned(
        self, operator: ValidateTIDESToGCSOperator
    ):
        assert operator.outcome_object_name() == os.path.join(
            "validation_outcomes/vehicle_locations",
            "dt=2026-04-01",
            "ts=2026-04-01T00:00:00+00:00",
            f"base64_url={self.base64_feed}",
            f"validate_{self.base64_feed}.jsonl.gz",
        )

    def test_export_query_filters_by_service_date_and_key(
        self, operator: ValidateTIDESToGCSOperator
    ):
        query = operator.export_query()
        assert "FROM `mart_tides.fct_tides_vehicle_locations`" in query
        assert "WHERE service_date = DATE @service_date" in query
        assert "AND gtfs_dataset_key = @gtfs_dataset_key" in query
        assert "SELECT * EXCEPT" in query
        assert "base64_url" in query
        assert "dt" in query
        assert "gtfs_dataset_key" in query

    def test_export_query_appends_limit_when_row_limit_set(
        self, test_dag: DAG, execution_date: datetime
    ):
        operator = ValidateTIDESToGCSOperator(
            task_id="vehicle_locations_validate_limited",
            gcp_conn_id="google_cloud_default",
            dt=execution_date.strftime("%Y-%m-%d"),
            ts=execution_date.isoformat(),
            dataset_id="mart_tides",
            table_name="fct_tides_vehicle_locations",
            service_date="2026-03-31",
            gtfs_dataset_key="9edf45e373638700ca420b1e588efdaf",
            feed_name="Beach Cities Transit Vehicle Positions",
            feed_url=self.feed_url,
            schema_url="https://example.com/schema.json",
            destination_bucket="gs://test-bucket",
            outcome_path_prefix="validation_outcomes/vehicle_locations",
            row_limit=100,
            dag=test_dag,
        )
        query = operator.export_query()
        assert "ORDER BY event_timestamp" in query
        assert "LIMIT 100" in query

    def test_time_column_for_trips_performed(
        self, test_dag: DAG, execution_date: datetime
    ):
        operator = ValidateTIDESToGCSOperator(
            task_id="trips_performed_validate",
            gcp_conn_id="google_cloud_default",
            dt=execution_date.strftime("%Y-%m-%d"),
            ts=execution_date.isoformat(),
            dataset_id="mart_tides",
            table_name="fct_tides_trips_performed",
            service_date="2026-03-31",
            gtfs_dataset_key="9edf45e373638700ca420b1e588efdaf",
            feed_name="Beach Cities Transit Vehicle Positions",
            feed_url=self.feed_url,
            schema_url="https://example.com/schema.json",
            destination_bucket="gs://test-bucket",
            outcome_path_prefix="validation_outcomes/trips_performed",
            row_limit=10,
            dag=test_dag,
        )
        assert operator.time_column() == "actual_trip_start"
        assert "ORDER BY actual_trip_start" in operator.export_query()

    def test_outcome_dict_for_valid_report(self, operator: ValidateTIDESToGCSOperator):
        report = FakeReport(
            valid=True,
            tasks=[FakeTask(errors=[])],
        )
        outcome = operator.outcome_dict(
            row_count=42,
            first_event="2026-03-31T00:00:01+00:00",
            last_event="2026-03-31T23:59:59+00:00",
            report=report,
            blob_path="gs://test-bucket/validation_outcomes/vehicle_locations/blob.jsonl.gz",
        )
        assert outcome["success"] is True
        assert outcome["exception"] is None
        assert outcome["step"] == "validate"
        assert outcome["header"] == {
            "row_count": 42,
            "feed_count": 1,
            "first_event_timestamp": "2026-03-31T00:00:01+00:00",
            "last_event_timestamp": "2026-03-31T23:59:59+00:00",
            "frictionless_valid": True,
            "error_counts_by_type": {},
        }
        assert outcome["extract"]["filename"] == self.base64_feed
        assert outcome["extract"]["config"]["feed_type"] == "tides_vehicle_locations"
        assert (
            outcome["extract"]["config"]["warehouse_table"]
            == "fct_tides_vehicle_locations"
        )
        assert (
            outcome["aggregation"]["filename"]
            == f"validate_{self.base64_feed}.jsonl.gz"
        )
        assert outcome["aggregation"]["step"] == "validate"
        assert outcome["aggregation"]["first_extract"] == outcome["extract"]
        assert outcome["process_stderr"] is None

    def test_outcome_dict_for_invalid_report_summarizes_errors(
        self, operator: ValidateTIDESToGCSOperator
    ):
        report = FakeReport(
            valid=False,
            tasks=[
                FakeTask(
                    errors=[
                        FakeError("constraint-error"),
                        FakeError("constraint-error"),
                        FakeError("type-error"),
                    ]
                )
            ],
        )
        outcome = operator.outcome_dict(
            row_count=10,
            first_event=None,
            last_event=None,
            report=report,
            blob_path="gs://test-bucket/blob.jsonl.gz",
        )
        assert outcome["success"] is False
        assert outcome["exception"] == "constraint-error=2; type-error=1"
        assert outcome["header"]["frictionless_valid"] is False
        assert outcome["header"]["error_counts_by_type"] == {
            "constraint-error": 2,
            "type-error": 1,
        }

    def test_outcome_dict_when_report_is_none(
        self, operator: ValidateTIDESToGCSOperator
    ):
        outcome = operator.outcome_dict(
            row_count=0,
            first_event=None,
            last_event=None,
            report=None,
            blob_path="gs://test-bucket/blob.jsonl.gz",
            process_stderr="RuntimeError('schema fetch failed')",
            exception="schema fetch failed",
        )
        assert outcome["success"] is False
        assert outcome["exception"] == "schema fetch failed"
        assert outcome["process_stderr"] == "RuntimeError('schema fetch failed')"
        assert outcome["header"]["frictionless_valid"] is False
        assert outcome["header"]["error_counts_by_type"] == {}
        assert outcome["header"]["row_count"] == 0
        assert outcome["header"]["feed_count"] == 0

    def test_execute_writes_jsonl_outcome_on_validation_pass(
        self,
        operator: ValidateTIDESToGCSOperator,
        monkeypatch,
    ):
        report = FakeReport(valid=True, tasks=[FakeTask(errors=[])])
        monkeypatch.setitem(sys.modules, "frictionless", _frictionless_stub(report))

        mock_bq_client = MagicMock()
        mock_bq_client.project = "cal-itp-data-infra-staging"
        mock_bq_hook = MagicMock()
        mock_bq_hook.get_client.return_value = mock_bq_client
        monkeypatch.setattr(operator, "bigquery_hook", lambda: mock_bq_hook)
        monkeypatch.setattr(
            "google.cloud.bigquery.Client", lambda **kwargs: MagicMock()
        )

        monkeypatch.setattr(operator, "fetch_schema", lambda: MagicMock())
        monkeypatch.setattr(
            operator,
            "export_parquet",
            lambda client, parquet_path: (
                42,
                "2026-03-31T00:00:01+00:00",
                "2026-03-31T23:59:59+00:00",
            ),
        )
        capturing_hook = CapturingGCSHook()
        monkeypatch.setattr(operator, "gcs_hook", lambda: capturing_hook)

        result = operator.execute(context={})

        expected_object = operator.outcome_object_name()
        expected_blob = os.path.join(
            os.environ.get("CALITP_BUCKET__TIDES_PUBLISH"), expected_object
        )
        assert result == {
            "dt": "2026-04-01",
            "ts": "2026-04-01T00:00:00+00:00",
            "blob_path": expected_blob,
            "success": True,
            "row_count": 42,
        }

        assert len(capturing_hook.uploads) == 1
        upload = capturing_hook.uploads[0]
        assert upload["bucket_name"] == os.environ.get(
            "CALITP_BUCKET__TIDES_PUBLISH"
        ).replace("gs://", "")
        assert upload["object_name"] == expected_object
        assert upload["mime_type"] == "application/jsonl"

        outcome = json.loads(gzip.decompress(upload["data"]))
        assert outcome["success"] is True
        assert outcome["step"] == "validate"
        assert outcome["header"]["row_count"] == 42
        assert outcome["header"]["frictionless_valid"] is True
        assert outcome["header"]["error_counts_by_type"] == {}
        assert outcome["blob_path"] == expected_blob
        assert outcome["extract"]["config"]["service_date"] == "2026-03-31"
        assert (
            outcome["extract"]["config"]["gtfs_dataset_key"]
            == "9edf45e373638700ca420b1e588efdaf"
        )

        partitioned_metadata = json.loads(
            upload["metadata"]["PARTITIONED_ARTIFACT_METADATA"]
        )
        assert partitioned_metadata == {
            "filename": f"validate_{self.base64_feed}.jsonl.gz",
            "ts": "2026-04-01T00:00:00+00:00",
            "feed_type": "tides_vehicle_locations",
            "base64_url": self.base64_feed,
        }

    def test_execute_writes_failure_outcome_on_validation_errors(
        self,
        operator: ValidateTIDESToGCSOperator,
        monkeypatch,
    ):
        report = FakeReport(
            valid=False,
            tasks=[
                FakeTask(
                    errors=[
                        FakeError("constraint-error"),
                        FakeError("constraint-error"),
                        FakeError("type-error"),
                    ]
                )
            ],
        )
        monkeypatch.setitem(sys.modules, "frictionless", _frictionless_stub(report))

        mock_bq_client = MagicMock()
        mock_bq_client.project = "cal-itp-data-infra-staging"
        mock_bq_hook = MagicMock()
        mock_bq_hook.get_client.return_value = mock_bq_client
        monkeypatch.setattr(operator, "bigquery_hook", lambda: mock_bq_hook)
        monkeypatch.setattr(
            "google.cloud.bigquery.Client", lambda **kwargs: MagicMock()
        )

        monkeypatch.setattr(operator, "fetch_schema", lambda: MagicMock())
        monkeypatch.setattr(
            operator,
            "export_parquet",
            lambda client, parquet_path: (10, None, None),
        )
        capturing_hook = CapturingGCSHook()
        monkeypatch.setattr(operator, "gcs_hook", lambda: capturing_hook)

        result = operator.execute(context={})

        assert result["success"] is False
        assert result["row_count"] == 10

        outcome = json.loads(gzip.decompress(capturing_hook.uploads[0]["data"]))
        assert outcome["success"] is False
        assert outcome["exception"] == "constraint-error=2; type-error=1"
        assert outcome["header"]["frictionless_valid"] is False
        assert outcome["header"]["error_counts_by_type"] == {
            "constraint-error": 2,
            "type-error": 1,
        }

    def test_execute_writes_failure_outcome_when_schema_fetch_raises(
        self,
        operator: ValidateTIDESToGCSOperator,
        monkeypatch,
    ):
        monkeypatch.setitem(
            sys.modules, "frictionless", _frictionless_stub(report=None)
        )

        mock_bq_client = MagicMock()
        mock_bq_client.project = "cal-itp-data-infra-staging"
        mock_bq_hook = MagicMock()
        mock_bq_hook.get_client.return_value = mock_bq_client
        monkeypatch.setattr(operator, "bigquery_hook", lambda: mock_bq_hook)
        monkeypatch.setattr(
            "google.cloud.bigquery.Client", lambda **kwargs: MagicMock()
        )

        def boom():
            raise RuntimeError("schema fetch failed")

        monkeypatch.setattr(operator, "fetch_schema", boom)
        capturing_hook = CapturingGCSHook()
        monkeypatch.setattr(operator, "gcs_hook", lambda: capturing_hook)

        result = operator.execute(context={})

        assert result["success"] is False
        assert result["row_count"] == 0

        outcome = json.loads(gzip.decompress(capturing_hook.uploads[0]["data"]))
        assert outcome["success"] is False
        assert outcome["exception"] == "schema fetch failed"
        assert outcome["process_stderr"] == "RuntimeError('schema fetch failed')"
        assert outcome["header"]["row_count"] == 0
        assert outcome["header"]["feed_count"] == 0
        assert outcome["header"]["error_counts_by_type"] == {}
