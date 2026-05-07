import os
from datetime import datetime, timezone

import pytest
from dateutil.relativedelta import relativedelta
from operators.dbt_bigquery_to_parquet_gcs_operator import (
    DBTBigQueryToParquetGCSOperator,
)

from airflow.models.dag import DAG


class TestDBTBigQueryToParquetGCSOperator:
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
                "end_date": execution_date + relativedelta(months=+1),
            },
            schedule=relativedelta(months=+1),
        )

    @pytest.fixture
    def operator(self, test_dag: DAG) -> DBTBigQueryToParquetGCSOperator:
        return DBTBigQueryToParquetGCSOperator(
            task_id="vehicle_locations_export",
            gcp_conn_id="google_cloud_default",
            destination_bucket_name=os.environ.get("CALITP_BUCKET__TIDES_PUBLISH"),
            destination_object_name=os.path.join(
                "vehicle_locations",
                "dt=2026-04-01",
                "ts=2026-04-01T00:00:00+00:00",
                "agency=hermosa_beach_transit",
                "vehicle_locations.parquet",
            ),
            dataset_id="mart_tides",
            table_name="fct_tides_vehicle_locations",
            dag=test_dag,
        )

    def test_destination_joins_bucket_and_object(
        self, operator: DBTBigQueryToParquetGCSOperator
    ):
        assert operator.destination() == os.path.join(
            os.environ.get("CALITP_BUCKET__TIDES_PUBLISH"),
            "vehicle_locations",
            "dt=2026-04-01",
            "ts=2026-04-01T00:00:00+00:00",
            "agency=hermosa_beach_transit",
            "vehicle_locations.parquet",
        )

    def test_query_renders_export_data_template(
        self, operator: DBTBigQueryToParquetGCSOperator
    ):
        query = operator.query()
        assert "EXPORT DATA OPTIONS(" in query
        assert f"uri='{operator.destination()}'" in query
        assert "format='PARQUET'" in query
        assert "compression='SNAPPY'" in query
        assert "overwrite=true" in query
        assert "SELECT * FROM mart_tides.fct_tides_vehicle_locations" in query

    def test_execute_runs_query_and_returns_prefix(
        self,
        operator: DBTBigQueryToParquetGCSOperator,
        monkeypatch,
    ):
        captured_queries: list[str] = []

        class MockClient:
            def query_and_wait(self, query: str):
                captured_queries.append(query)

        class MockBigQueryHook:
            def get_client(self):
                return MockClient()

        monkeypatch.setattr(operator, "bigquery_hook", lambda: MockBigQueryHook())

        result = operator.execute(context={})

        assert captured_queries == [operator.query()]
        assert result == {
            "destination_path_prefix": os.path.dirname(operator.destination())
        }

    def test_execute_propagates_query_failure(
        self,
        operator: DBTBigQueryToParquetGCSOperator,
        monkeypatch,
    ):
        class FailingClient:
            def query_and_wait(self, query: str):
                raise RuntimeError("BigQuery export failed")

        class MockBigQueryHook:
            def get_client(self):
                return FailingClient()

        monkeypatch.setattr(operator, "bigquery_hook", lambda: MockBigQueryHook())

        with pytest.raises(RuntimeError, match="BigQuery export failed"):
            operator.execute(context={})
