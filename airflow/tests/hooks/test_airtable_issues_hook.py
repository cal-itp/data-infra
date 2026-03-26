from __future__ import annotations

import pytest
from hooks.airtable_issues_hook import AirtableIssuesHook


class TestAirtableIssuesHook:
    @pytest.fixture
    def hook(self) -> AirtableIssuesHook:
        return AirtableIssuesHook(airtable_conn_id="airtable_issue_management")

    @pytest.mark.vcr
    def test_read(self, hook: AirtableIssuesHook):
        rows = hook.read(
            air_base_id="appmBGOFTvsDv4jdJ",
            air_table_name="Transit Data Quality Issues",
        )

        assert isinstance(rows, list)
        assert len(rows) > 0

        matching_row = next(row for row in rows if row["fields"]["Issue #"] == 508)

        assert matching_row["id"] == "rec01Z2lofJPGfBu4"
        assert matching_row["fields"]["Status"] == "Fixed - on its own"
        assert matching_row["fields"]["Created By"]["name"] == "Farhad Salemi"
