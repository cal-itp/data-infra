import pytest
from hooks.soda_hook import SODAHook


class TestSODAHook:
    @pytest.fixture
    def hook(self) -> SODAHook:
        return SODAHook(method="GET", http_conn_id="http_ntd")

    @pytest.mark.vcr()
    def test_total_pages(self, hook: SODAHook):
        assert hook.total_pages(resource="i4ua-cjx4") == 7

    @pytest.mark.vcr()
    def test_page(self, hook: SODAHook):
        result = hook.page(resource="i4ua-cjx4", page=1, limit=1)
        assert len(result) == 1
        assert result[0] == result[0] | {
            "max_agency": "King County, dba: King County Metro",
            "max_city": "Seattle",
            "max_organization_type": "City, County or Local Government Unit or Department of Transportation",
            "max_uace_code": "80389",
            "max_uza_name": "Seattle--Tacoma, WA",
            "ntd_id": "00001",
        }
