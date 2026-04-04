"""
Test: AirtableIssuesCreateOperator

Purpose:
This test verifies the behavior of the AirtableIssuesCreateOperator without making
real calls to Airtable.

Approach:
This test does not attempt to perform a real-write VCR cassette against
production-like Airtable records. Instead, it uses a mock-based approach.

It uses pytest's monkeypatch to replace the Airtable hook's batch_create() method
with a fake function, ensuring that no real API calls are made.

The operator under test pulls some sample rows,
transforms the data into Airtable create payloads, and invokes the mocked hook.

Assertions validate that:
- The transformation logic is correct
- The expected payload is sent to the hook
- The operator returns the correct XCom output

Notes:
- This is a unit test for operator logic only (not an Airtable integration test)
- No actual Airtable records are created
"""

from __future__ import annotations

from datetime import date, datetime, timedelta, timezone

import pytest
from operators.airtable_issues_create_operator import AirtableIssuesCreateOperator

from airflow.models.dag import DAG
from airflow.models.taskinstance import TaskInstance


class TestAirtableIssuesCreateOperator:
    @pytest.fixture
    def execution_date(self) -> datetime:
        return datetime.fromisoformat("2026-01-01").replace(tzinfo=timezone.utc)

    @pytest.fixture
    def sample_rows(self) -> list[dict]:
        return [
            {
                "gtfs_dataset_name": "Dataset A",
                "gtfs_dataset_record_id": "rec_dataset_1",
                "service_name": "Service A",
                "service_record_id": "rec_service_1",
                "max_end_date": date(2026, 1, 15),
                "expiration_status": "Expired",
            },
            {
                "gtfs_dataset_name": "Dataset B",
                "gtfs_dataset_record_id": "rec_dataset_2",
                "service_name": "Service B",
                "service_record_id": "rec_service_2",
                "max_end_date": date(2026, 1, 30),
                "expiration_status": "Expiring",
            },
        ]

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
        self, test_dag: DAG, sample_rows: list[dict]
    ) -> AirtableIssuesCreateOperator:
        return AirtableIssuesCreateOperator(
            task_id="create_airtable_issues",
            airtable_conn_id="airtable_issue_management",
            air_base_id="test_base",
            air_table_name="test_table",
            rows=sample_rows,
            dag=test_dag,
        )

    def test_execute(
        self,
        operator: AirtableIssuesCreateOperator,
        execution_date: datetime,
        monkeypatch,
    ):
        captured = {}

        def fake_batch_create(self, air_base_id, air_table_name, records):
            captured["records"] = records
            return [
                {
                    "id": "rec_created_1",
                    "fields": {
                        "Issue #": 101,
                    },
                },
                {
                    "id": "rec_created_2",
                    "fields": {
                        "Issue #": 102,
                    },
                },
            ]

        monkeypatch.setattr(
            "hooks.airtable_issues_hook.AirtableIssuesHook.batch_create",
            fake_batch_create,
        )

        monkeypatch.setattr(operator, "today", lambda: "2026-01-01")

        operator.run(
            start_date=execution_date,
            end_date=execution_date + timedelta(days=1),
            ignore_first_depends_on_past=True,
        )

        ti = TaskInstance(operator, execution_date=execution_date)
        result = ti.xcom_pull()

        print("\n=== DEBUG OUTPUT ===")
        print("XCom:", result)
        print("Captured:", captured["records"])
        print("====================\n")

        assert result["created_count"] == 2
        assert result["created_record_ids"] == ["rec_created_1", "rec_created_2"]
        assert result["failed_batches"] == []

        assert captured["records"] == [
            {
                "fields": {
                    "Issue Type": ["recXHbaInR8Uebp5D"],
                    "GTFS Datasets": ["rec_dataset_1"],
                    "Status": "Outreach",
                    "Outreach Status": "Waiting on Customer Success",
                    "Description": "The feed expired on 2026-01-15.",
                    "Services": ["rec_service_1"],
                    "Waiting Since": "2026-01-01",
                }
            },
            {
                "fields": {
                    "Issue Type": ["recEmZkgNkfKgYe6N"],
                    "GTFS Datasets": ["rec_dataset_2"],
                    "Status": "Outreach",
                    "Outreach Status": "Waiting on Customer Success",
                    "Description": "The feed is about to expire on 2026-01-30.",
                    "Services": ["rec_service_2"],
                    "Waiting Since": "2026-01-01",
                }
            },
        ]

        assert result["email_rows"] == [
            {
                "issue_number": 101,
                "gtfs_dataset_name": "Dataset A",
                "service_name": "Service A",
                "expiration_status": "Expired",
                "max_end_date": "2026-01-15",
            },
            {
                "issue_number": 102,
                "gtfs_dataset_name": "Dataset B",
                "service_name": "Service B",
                "expiration_status": "Expiring",
                "max_end_date": "2026-01-30",
            },
        ]
