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
            columns=[
                "issue_number",
                "issue_source_record_id",
                "outreach_status",
                "gtfs_dataset_name",
                "new_end_date",
            ],
            dag=test_dag,
        )

    @pytest.mark.vcr
    def test_execute(
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
        expected = [
            {
                "issue_number": 1078,
                "issue_source_record_id": "rechtGSfdkkJZwDP4",
                "outreach_status": "Waiting on Customer Success",
                "gtfs_dataset_name": "Bay Area 511 County Connection Schedule",
                "new_end_date": "2026-06-06",
            },
            {
                "issue_number": 1084,
                "issue_source_record_id": "rec5BRnMbyZtBmVr0",
                "outreach_status": "Waiting on Transit Agency",
                "gtfs_dataset_name": "Big Blue Bus Schedule",
                "new_end_date": "2026-08-08",
            },
            {
                "issue_number": 1071,
                "issue_source_record_id": "reckV7n1rPNpsSEVk",
                "outreach_status": "Waiting on Transit Agency",
                "gtfs_dataset_name": "Imperial Valley Transit Schedule",
                "new_end_date": "2026-12-31",
            },
            {
                "issue_number": 1091,
                "issue_source_record_id": "recUUScFqcoCGvNzz",
                "outreach_status": "Waiting on Customer Success",
                "gtfs_dataset_name": "Bay Area 511 Sonoma-Marin Area Rail Transit Schedule",
                "new_end_date": "2027-01-10",
            },
        ]

        xcom_value_sorted = sorted(xcom_value, key=lambda row: row["issue_number"])
        expected_sorted = sorted(expected, key=lambda row: row["issue_number"])

        assert xcom_value_sorted == expected_sorted
