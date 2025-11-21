import pytest
from hooks.ntd_xlsx_hook import NTDXLSXHook


class TestNTDXLSXHook:
    @pytest.fixture
    def hook(self) -> NTDXLSXHook:
        return NTDXLSXHook(method="GET", http_conn_id="http_dot")

    @pytest.mark.vcr()
    def test_run(self, hook: NTDXLSXHook):
        assert (
            hook.run(
                endpoint="/ntd/data-product/2022-annual-database-agency-information"
            )
            == "/sites/fta.dot.gov/files/2024-07/2022%20Agency%20Information_1-3_0.xlsx"
        )
