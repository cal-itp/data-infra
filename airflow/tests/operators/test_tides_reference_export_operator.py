import os

import pytest
from operators.tides_reference_export_operator import TIDESReferenceExportOperator


class TestTIDESReferenceExportOperator:
    @pytest.fixture
    def operator(self) -> TIDESReferenceExportOperator:
        return TIDESReferenceExportOperator(
            task_id="export_reference_models",
            ts="2026-07-16T00:00:00+00:00",
            dataset_name="mart_tides",
            table_name="tides_organizations_latest",
            destination_bucket=os.environ.get("CALITP_BUCKET__TIDES"),
            destination_path_prefix="reference/tides_organizations_latest/",
            report_path="reference_outcomes/dt=2026-07-16/ts=2026-07-16T00:00:00+00:00/tides_organizations_latest_outcomes.jsonl",
            user_project=os.environ.get("GOOGLE_CLOUD_PROJECT"),
            gcp_conn_id="google_cloud_default",
        )

    def test_queries_export_parquet_and_csv(
        self, operator: TIDESReferenceExportOperator
    ):
        parquet_query, csv_query = operator.queries()

        bucket = os.environ.get("CALITP_BUCKET__TIDES")
        assert "format='PARQUET'" in parquet_query
        assert "compression='SNAPPY'" in parquet_query
        assert (
            f"uri='{bucket}/reference/tides_organizations_latest/data_*.parquet'"
            in parquet_query
        )

        assert "format='CSV'" in csv_query
        assert "header=true" in csv_query
        assert (
            f"uri='{bucket}/reference/tides_organizations_latest/data_*.csv'"
            in csv_query
        )

        for query in (parquet_query, csv_query):
            assert "SELECT * FROM `mart_tides.tides_organizations_latest`" in query
            assert "overwrite=true" in query
            assert "WHERE" not in query

    def test_report_metadata(self, operator: TIDESReferenceExportOperator):
        assert operator.report_metadata() == {
            "dataset_name": "mart_tides",
            "table_name": "tides_organizations_latest",
            "destination_parquet_path": "reference/tides_organizations_latest/data_*.parquet",
            "destination_csv_path": "reference/tides_organizations_latest/data_*.csv",
            "ts": "2026-07-16T00:00:00+00:00",
        }
