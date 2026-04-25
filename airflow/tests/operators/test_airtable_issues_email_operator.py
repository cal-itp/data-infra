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
            expiring_update_result={},
            expiring_create_result={},
            rt_update_result={},
        )

    @pytest.fixture
    def populated_expiring_update_result(self) -> dict:
        return {
            "email_rows": [
                {
                    "issue_number": "ISSUE-1",
                    "issue_type": "About to Expire Schedule Feed",
                    "gtfs_dataset_name": "Dataset A",
                    "service_name": "Service A",
                    "status": "Fixed - on its own",
                    "new_end_date": "2026-03-20",
                    "rt_completeness_percentage": "NA",
                },
            ],
            "failed_batches": [{"batch_num": 2, "error": "Partial failure"}],
            "updated_record_ids": ["rec1"],
        }

    @pytest.fixture
    def populated_rt_update_result(self) -> dict:
        return {
            "email_rows": [
                {
                    "issue_number": "ISSUE-2",
                    "issue_type": "GTFS Realtime Completeness Problem",
                    "gtfs_dataset_name": "Dataset B",
                    "service_name": "Service B",
                    "status": "Fixed - with Cal-ITP help",
                    "new_end_date": "NA",
                    "rt_completeness_percentage": 87.5,
                },
            ],
            "failed_batches": [{"batch_num": 3, "error": "RT update failure"}],
            "updated_record_ids": ["rec2"],
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
                    "organization_name": "Organization C",
                },
                {
                    "issue_number": "ISSUE-4",
                    "gtfs_dataset_name": "Dataset D",
                    "service_name": "Service D",
                    "expiration_status": "Expiring",
                    "max_end_date": "2026-03-30",
                    "organization_name": "Organization D",
                },
            ],
            "failed_batches": [{"batch_num": 1, "error": "Create failure"}],
            "created_record_ids": ["rec3", "rec4"],
        }

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
                    "issue_type": "About to Expire Schedule Feed",
                    "gtfs_dataset_name": "Dataset A",
                    "service_name": "Service A",
                    "status": "Fixed - on its own",
                    "new_end_date": "2026-03-20",
                    "rt_completeness_percentage": "NA",
                },
                {
                    "issue_number": "ISSUE-2",
                    "issue_type": "GTFS Realtime Completeness Problem",
                    "gtfs_dataset_name": "Dataset B",
                    "service_name": "Service B",
                    "status": "Fixed - with Cal-ITP help",
                    "new_end_date": "NA",
                    "rt_completeness_percentage": 87.5,
                },
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

        assert "Successfully closed 2 Airtable records." in body
        assert "ISSUE-1" in body
        assert "Dataset A" in body
        assert "Service A" in body
        assert "Fixed - on its own" in body
        assert "ISSUE-2" in body
        assert "87.5%" in body

        assert (
            "Successfully created 1 About to Expire Issues in Airtable and HubSpot."
            in body
        )
        assert "ISSUE-3" in body
        assert "Dataset C" in body
        assert "Service C" in body
        assert "Expired" in body

        assert "Batch 3: Update failure" in body
        assert "Batch 4: Create failure" in body

    def test_execute_no_created_updated_or_failed_batches(self):
        operator = AirtableIssuesEmailOperator(
            task_id="send_airtable_issue_email",
            to_emails=["airtable-issue-alerts@dot.ca.gov"],
            subject="[Airflow] Airtable Issue Management",
            expiring_update_result={
                "email_rows": [],
                "failed_batches": [],
                "updated_record_ids": [],
            },
            expiring_create_result={
                "email_rows": [],
                "failed_batches": [],
                "created_record_ids": [],
            },
            rt_update_result={
                "email_rows": [],
                "failed_batches": [],
                "updated_record_ids": [],
            },
        )

        result = operator.execute(context={})

        assert result == {
            "email_sent": False,
            "reason": "no_updated_or_created_rows",
        }

    def test_execute_sends_email(
        self,
        populated_expiring_update_result,
        populated_rt_update_result,
        populated_create_result,
        monkeypatch,
    ):
        sent_emails = []

        def mock_send_email(to, subject, html_content):
            sent_emails.append(
                {
                    "to": to,
                    "subject": subject,
                    "html_content": html_content,
                }
            )

        monkeypatch.setattr(
            "operators.airtable_issues_email_operator.send_email",
            mock_send_email,
        )
        monkeypatch.setenv("HUBSPOT_NOTIFICATION_EMAIL", "hubspot@example.com")

        operator = AirtableIssuesEmailOperator(
            task_id="send_airtable_issue_email",
            to_emails=["airtable-issue-alerts@dot.ca.gov"],
            subject="[Airflow] Airtable Issue Management",
            expiring_update_result=populated_expiring_update_result,
            expiring_create_result=populated_create_result,
            rt_update_result=populated_rt_update_result,
        )

        result = operator.execute(context={})

        assert len(sent_emails) == 3

        summary_email = sent_emails[-1]
        assert summary_email["to"] == ["airtable-issue-alerts@dot.ca.gov"]
        assert (
            "Successfully created 2 About to Expire Issues in Airtable and HubSpot."
            in summary_email["html_content"]
        )
        assert (
            "Successfully closed 2 Airtable records." in summary_email["html_content"]
        )
        assert "87.5%" in summary_email["html_content"]

        assert result == {
            "email_sent": True,
            "updated_count": 2,
            "created_count": 2,
            "updated_record_ids": ["rec1", "rec2"],
            "created_record_ids": ["rec3", "rec4"],
            "failed_update_batches": [
                {"batch_num": 2, "error": "Partial failure"},
                {"batch_num": 3, "error": "RT update failure"},
            ],
            "failed_create_batches": [{"batch_num": 1, "error": "Create failure"}],
        }
