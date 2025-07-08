import pytest
from hooks.airtable_hook import AirtableHook


class TestAirtableHook:
    @pytest.fixture
    def hook(self) -> AirtableHook:
        return AirtableHook(airtable_conn_id="airtable_default")

    @pytest.mark.vcr()
    def test_retrieve(self, hook: AirtableHook):
        result = hook.read(
            air_base_id="appPnJWrQ7ui4UmIl", air_table_name="county geography"
        )
        assert "id" in result[0]
        assert "createdTime" in result[0]
        assert "fields" in result[0]
        assert isinstance(result[0]["fields"], dict)
