from __future__ import annotations

from unittest.mock import MagicMock

import pytest
from operators.airtable_issues_email_operator import AirtableIssuesEmailOperator


class TestAirtableIssuesEmailOperator:
    # Fixture to create a reusable instance of the email operator
    @pytest.fixture
    def operator(self) -> AirtableIssuesEmailOperator:
        return AirtableIssuesEmailOperator(
            task_id="send_airtable_issue_email",
            to_emails=["airtable-issue-alerts@dot.ca.gov"],
            subject="[Airflow] Airtable Issue Management",
            source_task_id="update_airtable_issues",
        )

    # Test that build_failed_html returns "None" when there are no failed batches
    def test_build_failed_html_none(self, operator: AirtableIssuesEmailOperator):
        result = operator.build_failed_html([])

        assert result == "None"

    # Test that build_failed_html correctly formats multiple failed batches
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

    # Test that build_email_body produces correct HTML content with rows and failures
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

    # Test execute() behavior when no XCom result is returned
    def test_execute_no_update_result(self, operator: AirtableIssuesEmailOperator):
        mock_ti = MagicMock()
        mock_ti.xcom_pull.return_value = None

        context = {"ti": mock_ti}

        result = operator.execute(context=context)

        mock_ti.xcom_pull.assert_called_once_with(task_ids="update_airtable_issues")
        assert result == {
            "email_sent": False,
            "reason": "no_update_result",
        }

    # Test execute() behavior when XCom exists but no rows were updated
    def test_execute_no_updated_rows(self, operator: AirtableIssuesEmailOperator):
        mock_ti = MagicMock()
        mock_ti.xcom_pull.return_value = {
            "email_rows": [],
            "failed_batches": [],
            "updated_record_ids": [],
        }

        context = {"ti": mock_ti}

        result = operator.execute(context=context)

        mock_ti.xcom_pull.assert_called_once_with(task_ids="update_airtable_issues")
        assert result == {
            "email_sent": False,
            "reason": "no_updated_rows",
        }

    # Test execute() happy path: email is "sent" and content is correct
    def test_execute_sends_email(
        self,
        operator: AirtableIssuesEmailOperator,
        monkeypatch: pytest.MonkeyPatch,
    ):
        sent = {}

        # Mock function to replace Airflow's send_email
        # Captures arguments instead of sending a real email
        def mock_send_email(to, subject, html_content):
            sent["to"] = to
            sent["subject"] = subject
            sent["html_content"] = html_content

        # Patch the send_email function inside the operator module
        monkeypatch.setattr(
            "operators.airtable_issues_email_operator.send_email",
            mock_send_email,
        )
        mock_ti = MagicMock()
        mock_ti.xcom_pull.return_value = {
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

        context = {"ti": mock_ti}

        result = operator.execute(context=context)

        mock_ti.xcom_pull.assert_called_once_with(task_ids="update_airtable_issues")

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
