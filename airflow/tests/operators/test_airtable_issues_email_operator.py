from __future__ import annotations

import pytest
from operators.airtable_issues_email_operator import AirtableIssuesEmailOperator


class TestAirtableIssuesEmailOperator:
    @pytest.fixture
    def operator(self) -> AirtableIssuesEmailOperator:
        return AirtableIssuesEmailOperator(
            task_id="send_airtable_issue_email",
            to_emails=["airtable-issue-alerts@dot.ca.gov"],
            subject="[Airflow] Airtable Issue Management",
            update_result={},
            create_result={},
        )

    @pytest.fixture
    def populated_update_result(self) -> dict:
        return {
            "email_rows": [
                {
                    "issue_number": "ISSUE-1",
                    "gtfs_dataset_name": "Dataset A",
                    "status": "Fixed - on its own",
                    "new_end_date": "2026-03-20",
                },
                {
                    "issue_number": "ISSUE-2",
                    "gtfs_dataset_name": "Dataset B",
                    "status": "Fixed - with Cal-ITP help",
                    "new_end_date": "2026-03-21",
                },
            ],
            "failed_batches": [{"batch_num": 2, "error": "Partial failure"}],
            "updated_record_ids": ["rec1", "rec2"],
        }

    @pytest.fixture
    def populated_create_result(self) -> dict:
        return {
            "email_rows": [
                {
                    "issue_number": "ISSUE-3",
                    "gtfs_dataset_name": "Dataset C",
                    "service_name": "Service C",
                    "expiration_status": "Expired",
                    "max_end_date": "2026-03-25",
                },
                {
                    "issue_number": "ISSUE-4",
                    "gtfs_dataset_name": "Dataset D",
                    "service_name": "Service D",
                    "expiration_status": "Expiring",
                    "max_end_date": "2026-03-30",
                },
            ],
            "failed_batches": [{"batch_num": 1, "error": "Create failure"}],
            "created_record_ids": ["rec3", "rec4"],
        }

    def test_build_failed_html_none(self, operator):
        assert operator.build_failed_html([]) == "None"

    def test_build_failed_html_with_batches(self, operator):
        failed_batches = [
            {"batch_num": 1, "error": "Boom 1"},
            {"batch_num": 2, "error": "Boom 2"},
        ]

        result = operator.build_failed_html(failed_batches)

        assert "Batch 1: Boom 1" in result
        assert "Batch 2: Boom 2" in result
        assert "<br>" in result

    def test_build_email_body(self, operator):
        body = operator.build_email_body(
            closed_email_rows=[
                {
                    "issue_number": "ISSUE-1",
                    "gtfs_dataset_name": "Dataset A",
                    "status": "Fixed - on its own",
                    "new_end_date": "2026-03-20",
                }
            ],
            closed_failed_batches=[{"batch_num": 3, "error": "Update failure"}],
            created_email_rows=[
                {
                    "issue_number": "ISSUE-3",
                    "gtfs_dataset_name": "Dataset C",
                    "service_name": "Service C",
                    "expiration_status": "Expired",
                    "max_end_date": "2026-03-25",
                }
            ],
            created_failed_batches=[{"batch_num": 4, "error": "Create failure"}],
        )

        # Closed section
        assert "Closed the following About to Expire Issues:" in body
        assert "ISSUE-1" in body
        assert "Dataset A" in body
        assert "Fixed - on its own" in body

        # Created section
        assert "Created the following About to Expire Issues:" in body
        assert "ISSUE-3" in body
        assert "Dataset C" in body
        assert "Service C" in body
        assert "Expired" in body

        # Failures
        assert "Batch 3: Update failure" in body
        assert "Batch 4: Create failure" in body

    def test_execute_no_updated_or_created_rows(self):
        operator = AirtableIssuesEmailOperator(
            task_id="send_airtable_issue_email",
            to_emails=["airtable-issue-alerts@dot.ca.gov"],
            subject="[Airflow] Airtable Issue Management",
            update_result={
                "email_rows": [],
                "failed_batches": [],
                "updated_record_ids": [],
            },
            create_result={
                "email_rows": [],
                "failed_batches": [],
                "created_record_ids": [],
            },
        )

        result = operator.execute(context={})

        assert result == {
            "email_sent": False,
            "reason": "no_updated_or_created_rows",
        }

    def test_execute_sends_email(
        self,
        populated_update_result,
        populated_create_result,
        monkeypatch,
    ):
        sent = {}

        def mock_send_email(to, subject, html_content):
            sent["to"] = to
            sent["subject"] = subject
            sent["html_content"] = html_content

        monkeypatch.setattr(
            "operators.airtable_issues_email_operator.send_email",
            mock_send_email,
        )

        operator = AirtableIssuesEmailOperator(
            task_id="send_airtable_issue_email",
            to_emails=["airtable-issue-alerts@dot.ca.gov"],
            subject="[Airflow] Airtable Issue Management",
            update_result=populated_update_result,
            create_result=populated_create_result,
        )

        result = operator.execute(context={})

        assert sent["to"] == ["airtable-issue-alerts@dot.ca.gov"]
        assert "Successfully updated 2 Airtable records" in sent["html_content"]
        assert "Successfully created 2 Airtable records" in sent["html_content"]

        assert result == {
            "email_sent": True,
            "updated_count": 2,
            "created_count": 2,
            "updated_record_ids": ["rec1", "rec2"],
            "created_record_ids": ["rec3", "rec4"],
            "failed_update_batches": [{"batch_num": 2, "error": "Partial failure"}],
            "failed_create_batches": [{"batch_num": 1, "error": "Create failure"}],
        }
