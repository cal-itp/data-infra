import gzip
import json
import os
from datetime import datetime, timedelta, timezone

import pytest
from operators.ntd_xlsx_to_jsonl_operator import NTDXLSXToJSONLOperator

from airflow.models.dag import DAG
from airflow.models.taskinstance import TaskInstance
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class TestNTDXLSXToJSONLOperator:
    @pytest.fixture
    def execution_date(self) -> datetime:
        return datetime.fromisoformat("2025-06-02").replace(tzinfo=timezone.utc)

    @pytest.fixture
    def gcs_hook(self) -> GCSHook:
        return GCSHook()

    @pytest.fixture
    def source_path(self) -> str:
        return "annual_database_agency_information_raw/2022/dt=2025-06-02/execution_ts=2025-06-02T00:00:00+00:00/2022__annual_database_agency_information_raw.xlsx"

    @pytest.fixture
    def destination_path(self) -> str:
        return "annual_database_agency_information/2022/_2022_agency_information/dt=2025-06-02/execution_ts=2025-06-02T18:24:18.267031+00:00/2022__annual_database_agency_information___2022_agency_information.jsonl.gz"

    @pytest.fixture
    def test_dag(self, execution_date: datetime) -> DAG:
        return DAG(
            "test_dag",
            default_args={
                "owner": "airflow",
                "start_date": execution_date,
                "end_date": execution_date + timedelta(days=1),
            },
            schedule=timedelta(days=1),
        )

    @pytest.fixture
    def operator(
        self,
        test_dag: DAG,
        execution_date: datetime,
        destination_path: str,
        source_path: str,
    ) -> NTDXLSXToJSONLOperator:
        return NTDXLSXToJSONLOperator(
            task_id="ntd_xlsx_to_jsonl",
            gcp_conn_id="google_cloud_default",
            tab="2022 Agency Information",
            source_bucket=os.environ.get("CALITP_BUCKET__NTD_XLSX_DATA_PRODUCTS__RAW"),
            source_path=source_path,
            destination_bucket=os.environ.get(
                "CALITP_BUCKET__NTD_XLSX_DATA_PRODUCTS__CLEAN"
            ),
            destination_path=destination_path,
            dag=test_dag,
        )

    @pytest.mark.vcr
    def test_execute(
        self,
        test_dag: DAG,
        operator: NTDXLSXToJSONLOperator,
        execution_date: datetime,
        gcs_hook: GCSHook,
    ):
        operator.run(
            start_date=execution_date,
            end_date=execution_date + timedelta(days=1),
            ignore_first_depends_on_past=True,
        )

        task = test_dag.get_task("ntd_xlsx_to_jsonl")
        task_instance = TaskInstance(task, execution_date=execution_date)
        xcom_value = task_instance.xcom_pull()
        assert xcom_value == {
            "destination_path": os.path.join(
                "annual_database_agency_information",
                "2022",
                "_2022_agency_information",
                "dt=2025-06-02",
                "execution_ts=2025-06-02T18:24:18.267031+00:00",
                "2022__annual_database_agency_information___2022_agency_information.jsonl.gz",
            ),
        }

        compressed_result = gcs_hook.download(
            bucket_name=os.environ.get(
                "CALITP_BUCKET__NTD_XLSX_DATA_PRODUCTS__CLEAN"
            ).replace("gs://", ""),
            object_name=xcom_value["destination_path"],
        )
        decompressed_result = gzip.decompress(compressed_result)
        result = [json.loads(x) for x in decompressed_result.splitlines()]
        assert result[0] == {
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
