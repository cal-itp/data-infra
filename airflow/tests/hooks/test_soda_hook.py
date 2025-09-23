import pytest
from hooks.soda_hook import SODAHook


class TestSODAHook:
    @pytest.fixture
    def hook(self) -> SODAHook:
        return SODAHook(method="GET", http_conn_id="http_ntd")

    @pytest.mark.vcr()
    def test_total_pages(self, hook: SODAHook):
        assert hook.total_pages(resource="i4ua-cjx4") == 5

    @pytest.mark.vcr()
    def test_page(self, hook: SODAHook):
        result = hook.page(resource="i4ua-cjx4", page=1, limit=1)
        print(result)
        assert result == [
            {
                "ntd_id": "00001",
                "max_agency": "King County, dba: King County Metro",
                "max_city": "Seattle",
                "max_state": "WA",
                "max_organization_type": "City, County or Local Government Unit or Department of Transportation",
                "max_reporter_type": "Full Reporter: Operating",
                "report_year": "2023",
                "max_uace_code": "80389",
                "max_uza_name": "Seattle--Tacoma, WA",
                "max_primary_uza_population": "3544011",
                "max_agency_voms": "2270",
                "sum_operators_wages": "197663733",
                "sum_other_salaries_wages": "153943360",
                "sum_operator_paid_absences": "25883676",
                "sum_other_paid_absences": "32428838",
                "sum_fringe_benefits": "176926831",
                "sum_services": "143782397",
                "sum_fuel_and_lube": "34638766",
                "sum_tires": "2979855",
                "sum_other_materials_supplies": "47511691",
                "sum_utilities": "7124526",
                "sum_casualty_and_liability": "27324766",
                "sum_taxes": "958881",
                "sum_purchased_transportation": "245525126",
                "sum_miscellaneous": "2304381",
                "sum_reduced_reporter_expenses": "0",
                "sum_total": "928694623",
                "sum_separate_report_amount": "170302204",
            }
        ]
