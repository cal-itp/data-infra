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
            type="annual_database_agency_information",
            year="2022",
            tab_name="2022 Agency Information",
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
            "type": "annual_database_agency_information",
            "year": "2022",
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
            "address_line_1": "201 S Jackson St",
            "address_line_2": "M.S. KSC-TR-0333",
            "agency_name": "King County Department of Metro Transit",
            "city": "Seattle",
            "density": "3607",
            "doing_business_as": "King County Metro",
            "fta_recipient_id": "1731",
            "fy_end_date": "2022-12-31 00:00:00",
            "legacy_ntd_id": "1",
            "ntd_id": "1",
            "organization_type": "City, County or Local Government Unit or Department of Transportation",
            "original_due_date": "2023-04-30 00:00:00",
            "population": "3544011",
            "primary_uza_uace_code": "80389",
            "region": "10",
            "reporter_acronym": "KCM",
            "reporter_type": "Full Reporter",
            "reporting_module": "Urban",
            "service_area_pop": "2287050",
            "service_area_sq_miles": "2134",
            "sq_miles": "982.52",
            "state": "WA",
            "tam_tier": "Tier I (Rail)",
            "total_voms": "2029",
            "ueid": "E1D1LQ5QENJ8",
            "url": "http://metro.kingcounty.gov/",
            "uza_name": "Seattle--Tacoma, WA",
            "voms_do": "1667",
            "voms_pt": "362",
            "zip_code": "98104",
            "zip_code_ext": "3854",
        }

    @pytest.fixture
    def unnamed_execution_date(self) -> datetime:
        return datetime.fromisoformat("2025-12-01").replace(tzinfo=timezone.utc)

    @pytest.fixture
    def unnamed_source_path(self) -> str:
        return "operating_and_capital_funding_time_series_raw/historical/dt=2025-12-01/execution_ts=2025-12-01T10:02:57.214757+00:00/historical__operating_and_capital_funding_time_series_raw.xlsx"

    @pytest.fixture
    def unnamed_destination_path(self) -> str:
        return "operating_and_capital_funding_time_series/historical/summary_total/dt=2025-12-01/execution_ts=2025-12-01T10:02:57.214757+00:00/historical__operating_and_capital_funding_time_series__summary_total.jsonl.gz"

    @pytest.fixture
    def test_unnamed_dag(self, unnamed_execution_date: datetime) -> DAG:
        return DAG(
            "test_unnamed_dag",
            default_args={
                "owner": "airflow",
                "start_date": unnamed_execution_date,
                "end_date": unnamed_execution_date + timedelta(days=1),
            },
            schedule=timedelta(days=1),
        )

    @pytest.fixture
    def unnamed_operator(
        self,
        test_unnamed_dag: DAG,
        unnamed_execution_date: datetime,
        unnamed_destination_path: str,
        unnamed_source_path: str,
    ) -> NTDXLSXToJSONLOperator:
        return NTDXLSXToJSONLOperator(
            task_id="unnamed_ntd_xlsx_to_jsonl",
            gcp_conn_id="google_cloud_default",
            type="operating_and_capital_funding_time_series",
            year="historical",
            tab_name="Summary Total",
            source_bucket=os.environ.get("CALITP_BUCKET__NTD_XLSX_DATA_PRODUCTS__RAW"),
            source_path=unnamed_source_path,
            destination_bucket=os.environ.get(
                "CALITP_BUCKET__NTD_XLSX_DATA_PRODUCTS__CLEAN"
            ),
            destination_path=unnamed_destination_path,
            dag=test_unnamed_dag,
        )

    @pytest.mark.vcr
    def test_unnamed_execute(
        self,
        test_unnamed_dag: DAG,
        unnamed_operator: NTDXLSXToJSONLOperator,
        unnamed_execution_date: datetime,
        gcs_hook: GCSHook,
    ):
        unnamed_operator.run(
            start_date=unnamed_execution_date,
            end_date=unnamed_execution_date + timedelta(days=1),
            ignore_first_depends_on_past=True,
        )

        task = test_unnamed_dag.get_task("unnamed_ntd_xlsx_to_jsonl")
        task_instance = TaskInstance(task, execution_date=unnamed_execution_date)
        xcom_value = task_instance.xcom_pull()
        assert xcom_value == {
            "type": "operating_and_capital_funding_time_series",
            "year": "historical",
            "destination_path": os.path.join(
                "operating_and_capital_funding_time_series",
                "historical",
                "summary_total",
                "dt=2025-12-01",
                "execution_ts=2025-12-01T10:02:57.214757+00:00",
                "historical__operating_and_capital_funding_time_series__summary_total.jsonl.gz",
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
            "federal": "Operating Federal",
            "local": "Operating Local",
            "national_total": "Operating Total",
            "other": "Operating Other",
            "state": "Operating State",
            "unnamed__0": "Year",
            "unnamed__2": "Capital Total",
            "unnamed__3": "Grand Total",
            "unnamed__5": "Capital Federal",
            "unnamed__6": "Total Federal",
            "unnamed__8": "Capital State",
            "unnamed__9": "Total State",
            "unnamed__11": "Capital Local",
            "unnamed__12": "Total Local",
            "unnamed__14": "Capital Other",
            "unnamed__15": "Total Other",
        }
