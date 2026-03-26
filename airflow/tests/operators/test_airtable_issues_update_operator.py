"""
Test: AirtableIssuesUpdateOperator

Purpose:
This test verifies the behavior of the AirtableIssuesUpdateOperator without making
real calls to Airtable.

Approach:
This test does not attempt to perform a real-write VCR cassette against
production-like Airtable records. Instead, it uses a mock-based approach.

It uses pytest's monkeypatch to replace the Airtable hook's batch_update() method
with a fake function, ensuring that no real API calls are made.

The operator under test pulls some sample rows,
transforms the data into Airtable update payloads, and invokes the mocked hook.

Assertions validate that:
- The transformation logic is correct
- The expected payload is sent to the hook
- The operator returns the correct XCom output

Notes:
- This is a unit test for operator logic only (not an Airtable integration test)
- No actual Airtable updates are performed
"""

from __future__ import annotations

from datetime import datetime, timedelta, timezone

import pytest
from operators.airtable_issues_update_operator import AirtableIssuesUpdateOperator

from airflow.models.dag import DAG
from airflow.models.taskinstance import TaskInstance


class TestAirtableIssuesUpdateOperator:
    @pytest.fixture
    def execution_date(self) -> datetime:
        return datetime.fromisoformat("2026-01-01").replace(tzinfo=timezone.utc)

    @pytest.fixture
    def sample_rows(self) -> list[dict]:
        return [
            {
                "issue_source_record_id": "rec1",
                "outreach_status": "Waiting on Customer Success",
            },
            {
                "issue_source_record_id": "rec2",
                "outreach_status": "Waiting on Transit Agency",
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
    ) -> AirtableIssuesUpdateOperator:
        return AirtableIssuesUpdateOperator(
            task_id="update_airtable_issues",
            airtable_conn_id="airtable_issue_management",
            air_base_id="test_base",
            air_table_name="test_table",
            rows=sample_rows,
            dag=test_dag,
        )

    def test_execute(
        self,
        operator: AirtableIssuesUpdateOperator,
        execution_date: datetime,
        monkeypatch,
    ):
        captured = {}

        def fake_batch_update(self, air_base_id, air_table_name, records):
            captured["records"] = records
            return [{"id": r["id"]} for r in records]

        monkeypatch.setattr(
            "hooks.airtable_issues_hook.AirtableIssuesHook.batch_update",
            fake_batch_update,
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

        assert result["updated_count"] == 2
        assert result["updated_record_ids"] == ["rec1", "rec2"]
        assert result["failed_batches"] == []

        assert captured["records"] == [
            {
                "id": "rec1",
                "fields": {
                    "Status": "Fixed - on its own",
                    "Outreach Status": None,
                    "Resolution Date": "2026-01-01",
                },
            },
            {
                "id": "rec2",
                "fields": {
                    "Status": "Fixed - with Cal-ITP help",
                    "Outreach Status": None,
                    "Resolution Date": "2026-01-01",
                },
            },
        ]
