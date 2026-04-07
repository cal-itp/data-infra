from datetime import datetime, timedelta, timezone

import pytest
from operators.tdq_bigquery_rows_operator import TDQBigQueryRowsOperator

from airflow.models.dag import DAG
from airflow.models.taskinstance import TaskInstance


class TestTDQBigQueryRowsOperator:
    @pytest.fixture
    def execution_date(self) -> datetime:
        return datetime.fromisoformat("2026-02-24").replace(tzinfo=timezone.utc)

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
    def operator(self, test_dag: DAG) -> TDQBigQueryRowsOperator:
        return TDQBigQueryRowsOperator(
            task_id="bq_close_expired_issues_candidates",
            gcp_conn_id="google_cloud_default",
            dataset_name="mart_transit_database",
            table_name="fct_close_expired_issues",
            dag=test_dag,
        )

    @pytest.mark.vcr
    def test_execute_returns_list_of_expected_shape(
        self,
        test_dag: DAG,
        operator: TDQBigQueryRowsOperator,
        execution_date: datetime,
    ):
        operator.run(
            start_date=execution_date,
            end_date=execution_date + timedelta(days=1),
            ignore_first_depends_on_past=True,
        )

        task = test_dag.get_task("bq_close_expired_issues_candidates")
        task_instance = TaskInstance(task, execution_date=execution_date)
        xcom_value = task_instance.xcom_pull()

        assert isinstance(xcom_value, list)

        expected_keys = {
            "issue_number",
            "issue_source_record_id",
            "outreach_status",
            "gtfs_dataset_name",
            "new_end_date",
            "service_name",
        }

        for row in xcom_value:
            assert isinstance(row, dict)
            assert set(row.keys()) == expected_keys
            assert row["issue_number"] is not None
            assert row["issue_source_record_id"] is not None

    def test_execute_maps_rows_correctly(self, test_dag: DAG, monkeypatch):
        operator = TDQBigQueryRowsOperator(
            task_id="bq_close_expired_issues_candidates",
            gcp_conn_id="google_cloud_default",
            dataset_name="mart_transit_database",
            table_name="fct_close_expired_issues",
            dag=test_dag,
        )

        mock_records = [
            (
                1078,
                "rechtGSfdkkJZwDP4",
                "Waiting on Customer Success",
                "Bay Area 511 County Connection Schedule",
                "2026-06-06",
                "County Connection",
            ),
            (
                1084,
                "rec5BRnMbyZtBmVr0",
                "Waiting on Transit Agency",
                "Big Blue Bus Schedule",
                "2026-08-08",
                "Big Blue Bus",
            ),
        ]

        mock_columns = [
            "issue_number",
            "issue_source_record_id",
            "outreach_status",
            "gtfs_dataset_name",
            "new_end_date",
            "service_name",
        ]

        class MockField:
            def __init__(self, name):
                self.name = name

        class MockRow:
            def __init__(self, values):
                self._values = values

            def values(self):
                return self._values

        class MockQueryResult:
            def __init__(self, columns, records):
                self.schema = [MockField(name) for name in columns]
                self._records = [MockRow(record) for record in records]

            def __iter__(self):
                return iter(self._records)

            def result(self):
                return self

        class MockClient:
            def query(self, sql):
                return MockQueryResult(mock_columns, mock_records)

        class MockBigQueryHook:
            def get_client(self):
                return MockClient()

        monkeypatch.setattr(
            operator,
            "bigquery_hook",
            lambda: MockBigQueryHook(),
        )

        result = operator.execute(context={})

        expected = [
            {
                "issue_number": 1078,
                "issue_source_record_id": "rechtGSfdkkJZwDP4",
                "outreach_status": "Waiting on Customer Success",
                "gtfs_dataset_name": "Bay Area 511 County Connection Schedule",
                "new_end_date": "2026-06-06",
                "service_name": "County Connection",
            },
            {
                "issue_number": 1084,
                "issue_source_record_id": "rec5BRnMbyZtBmVr0",
                "outreach_status": "Waiting on Transit Agency",
                "gtfs_dataset_name": "Big Blue Bus Schedule",
                "new_end_date": "2026-08-08",
                "service_name": "Big Blue Bus",
            },
        ]

        assert result == expected
