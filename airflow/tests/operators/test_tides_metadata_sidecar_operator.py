import os
from datetime import datetime, timezone

import pytest
from dateutil.relativedelta import relativedelta
from operators.tides_metadata_sidecar_operator import TidesMetadataSidecarOperator

from airflow.models.dag import DAG


class TestTidesMetadataSidecarOperator:
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
    def operator(self, test_dag: DAG) -> TidesMetadataSidecarOperator:
        return TidesMetadataSidecarOperator(
            task_id="metadata_sidecar",
            gcp_conn_id="google_cloud_default",
            destination_bucket_name=os.environ.get("CALITP_BUCKET__TIDES_PUBLISH"),
            destination_object_name=os.path.join(
                "metadata",
                "dt=2026-04-01",
                "ts=2026-04-01T00:00:00+00:00",
                "providers.json",
            ),
            dag=test_dag,
        )

    def test_default_dataset_and_table(self, operator: TidesMetadataSidecarOperator):
        assert operator.dataset_id == "mart_transit_database"
        assert operator.table_name == "dim_provider_gtfs_data"

    def test_destination_joins_bucket_and_object(
        self, operator: TidesMetadataSidecarOperator
    ):
        assert operator.destination() == os.path.join(
            os.environ.get("CALITP_BUCKET__TIDES_PUBLISH"),
            "metadata",
            "dt=2026-04-01",
            "ts=2026-04-01T00:00:00+00:00",
            "providers.json",
        )

    def test_query_selects_distinct_provider_columns(
        self, operator: TidesMetadataSidecarOperator
    ):
        query = operator.query()
        assert "EXPORT DATA OPTIONS(" in query
        assert f"uri='{operator.destination()}'" in query
        assert "format='JSON'" in query
        assert "overwrite=true" in query
        assert (
            "SELECT DISTINCT gtfs_dataset_key, organization_name, organization_ntd_id"
            in query
        )
        assert "FROM mart_transit_database.dim_provider_gtfs_data" in query
        assert (
            "WHERE public_customer_facing_or_regional_subfeed_fixed_route = TRUE"
            in query
        )
        assert "AND gtfs_dataset_key IS NOT NULL" in query
        assert "ORDER BY gtfs_dataset_key" in query

    def test_query_respects_overridden_dataset_and_table(self, test_dag: DAG):
        operator = TidesMetadataSidecarOperator(
            task_id="metadata_sidecar_override",
            gcp_conn_id="google_cloud_default",
            destination_bucket_name="gs://override-bucket",
            destination_object_name="providers.json",
            dataset_id="christopher_mart_transit_database",
            table_name="dim_provider_gtfs_data_v2",
            dag=test_dag,
        )
        query = operator.query()
        assert (
            "FROM christopher_mart_transit_database.dim_provider_gtfs_data_v2" in query
        )

    def test_execute_runs_query_and_returns_destination(
        self,
        operator: TidesMetadataSidecarOperator,
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
        assert result == operator.destination()

    def test_execute_propagates_query_failure(
        self,
        operator: TidesMetadataSidecarOperator,
        monkeypatch,
    ):
        class FailingClient:
            def query_and_wait(self, query: str):
                raise RuntimeError("metadata export failed")

        class MockBigQueryHook:
            def get_client(self):
                return FailingClient()

        monkeypatch.setattr(operator, "bigquery_hook", lambda: MockBigQueryHook())

        with pytest.raises(RuntimeError, match="metadata export failed"):
            operator.execute(context={})
