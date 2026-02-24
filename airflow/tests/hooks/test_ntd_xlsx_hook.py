import csv
import io

import openpyxl
import pytest
from hooks.ntd_xlsx_hook import NTDXLSXHook


class TestNTDXLSXHook:
    @pytest.fixture
    def hook(self) -> NTDXLSXHook:
        return NTDXLSXHook(method="GET", http_conn_id="http_dot")

    @pytest.mark.vcr()
    def test_run(self, hook: NTDXLSXHook):
        response = hook.run(
            endpoint="/ntd/data-product/2022-annual-database-agency-information"
        )
        workbook = openpyxl.load_workbook(filename=io.BytesIO(response.content))
        csv_file = io.StringIO()
        writer = csv.writer(csv_file)
        for row in workbook.active.rows:
            writer.writerow([cell.value for cell in row])
        csv_file.seek(0)

        assert list(csv.DictReader(csv_file))[0] == {
            "Address Line 1": "201 S Jackson St",
            "Address Line 2": "M.S. KSC-TR-0333",
            "Agency Name": "King County Department of Metro Transit",
            "City": "Seattle",
            "Density": "3607",
            "Doing Business As": "King County Metro",
            "FTA Recipient ID": "1731",
            "FY End Date": "2022-12-31 00:00:00",
            "Legacy NTD ID": "1",
            "NTD ID": "1",
            "Number of Counties with Service": "",
            "Number of State Counties": "",
            "Organization Type": "City, County or Local Government Unit or Department of Transportation",
            "Original Due Date": "2023-04-30 00:00:00",
            "P.O. Box": "",
            "Personal Vehicles": "",
            "Population": "3544011",
            "Primary UZA UACE Code": "80389",
            "Region": "10",
            "Reported By NTD ID": "",
            "Reported by Name": "",
            "Reporter Acronym": "KCM",
            "Reporter Type": "Full Reporter",
            "Reporting Module": "Urban",
            "Service Area Pop": "2287050",
            "Service Area Sq Miles": "2134",
            "Sq Miles": "982.52",
            "State": "WA",
            "State Admin Funds Expended": "",
            "State/Parent NTD ID": "",
            "Subrecipient Type": "",
            "TAM Tier": "Tier I (Rail)",
            "Total VOMS": "2029",
            "Tribal Area Name": "",
            "UEID": "E1D1LQ5QENJ8",
            "URL": "http://metro.kingcounty.gov/",
            "UZA Name": "Seattle--Tacoma, WA",
            "VOMS DO": "1667",
            "VOMS PT": "362",
            "Volunteer Drivers": "",
            "Zip Code": "98104",
            "Zip Code Ext": "3854",
        }
