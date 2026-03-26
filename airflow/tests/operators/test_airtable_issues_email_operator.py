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

    def test_build_failed_html_none(self, operator: AirtableIssuesEmailOperator):
        result = operator.build_failed_html([])

        assert result == "None"

    def test_build_failed_html_with_batches(
        self, operator: AirtableIssuesEmailOperator
    ):
        failed_batches = [
            {"batch_num": 1, "error": "Boom 1"},
            {"batch_num": 2, "error": "Boom 2"},
        ]

        result = operator.build_failed_html(failed_batches)

        assert "Batch 1: Boom 1" in result
        assert "Batch 2: Boom 2" in result
        assert "<br>" in result

    def test_build_email_body(self, operator: AirtableIssuesEmailOperator):
        email_rows = [
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
        ]
        failed_batches = [{"batch_num": 3, "error": "Test failure"}]

        body = operator.build_email_body(
            email_rows=email_rows,
            failed_batches=failed_batches,
        )

        assert "Successfully updated 2 Airtable records" in body
        assert "ISSUE-1" in body
        assert "Dataset A" in body
        assert "Fixed - on its own" in body
        assert "2026-03-20" in body
        assert "ISSUE-2" in body
        assert "Dataset B" in body
        assert "Fixed - with Cal-ITP help" in body
        assert "2026-03-21" in body
        assert "Batch 3: Test failure" in body

    def test_execute_no_update_result(self, operator: AirtableIssuesEmailOperator):
        result = operator.execute(context={})

        assert result == {
            "email_sent": False,
            "reason": "no_update_result",
        }

    def test_execute_no_updated_rows(self):
        operator = AirtableIssuesEmailOperator(
            task_id="send_airtable_issue_email",
            to_emails=["airtable-issue-alerts@dot.ca.gov"],
            subject="[Airflow] Airtable Issue Management",
            update_result={
                "email_rows": [],
                "failed_batches": [],
                "updated_record_ids": [],
            },
        )

        result = operator.execute(context={})

        assert result == {
            "email_sent": False,
            "reason": "no_updated_rows",
        }

    def test_execute_sends_email(
        self,
        populated_update_result: dict,
        monkeypatch: pytest.MonkeyPatch,
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
        )

        result = operator.execute(context={})

        assert sent["to"] == ["airtable-issue-alerts@dot.ca.gov"]
        assert sent["subject"] == "[Airflow] Airtable Issue Management"
        assert "Successfully updated 2 Airtable records" in sent["html_content"]
        assert "ISSUE-1" in sent["html_content"]
        assert "ISSUE-2" in sent["html_content"]
        assert "Batch 2: Partial failure" in sent["html_content"]

        assert result == {
            "email_sent": True,
            "updated_count": 2,
            "updated_record_ids": ["rec1", "rec2"],
            "failed_batches": [{"batch_num": 2, "error": "Partial failure"}],
        }
