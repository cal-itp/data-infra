from datetime import datetime, timedelta, timezone

import pytest
from operators.bigquery_to_airtable_issues_operator import (
    BigQueryToAirtableIssuesOperator,
)

from airflow.models.dag import DAG
from airflow.models.taskinstance import TaskInstance


class TestBigQueryToAirtableIssuesOperator:
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
    def operator(
        self, test_dag: DAG, execution_date: datetime
    ) -> BigQueryToAirtableIssuesOperator:
        return BigQueryToAirtableIssuesOperator(
            task_id="bigquery_to_airtable_issues",
            gcp_conn_id="google_cloud_default",
            dataset_name="mart_transit_database",
            table_name="fct_close_expired_issues",
            dag=test_dag,
        )

    @pytest.mark.vcr
    def test_execute(
        self,
        test_dag: DAG,
        operator: BigQueryToAirtableIssuesOperator,
        execution_date: datetime,
    ):
        operator.run(
            start_date=execution_date,
            end_date=execution_date + timedelta(days=1),
            ignore_first_depends_on_past=True,
        )

        task = test_dag.get_task("bigquery_to_airtable_issues")
        task_instance = TaskInstance(task, execution_date=execution_date)
        xcom_value = task_instance.xcom_pull()
        assert xcom_value == [
            {
                "issue_number": 1055,
                "issue_source_record_id": "recaIq01zJGDsiUPN",
                "outreach_status": "Waiting on Customer Success",
                "gtfs_dataset_name": "Amador Schedule",
                "new_end_date": "2026-09-01",
            },
            {
                "gtfs_dataset_name": "Long Beach Schedule",
                "issue_number": 1038,
                "issue_source_record_id": "recvnhNDNqts91J9k",
                "new_end_date": "2026-06-13",
                "outreach_status": "Waiting on Transit Agency",
            },
            {
                "gtfs_dataset_name": "Bay Area 511 South San Francisco Shuttle Schedule",
                "issue_number": 1007,
                "issue_source_record_id": "recuEj77mhWDYY4Xz",
                "new_end_date": "2027-01-01",
                "outreach_status": "Waiting on Transit Agency",
            },
        ]
