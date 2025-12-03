import os
from datetime import datetime, timedelta, timezone

import pytest
from operators.ntd_xlsx_list_tabs_operator import NTDXLSXListTabsOperator

from airflow.models.dag import DAG
from airflow.models.taskinstance import TaskInstance
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class TestNTDXLSXListTabsOperator:
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
    def operator(self, test_dag: DAG, source_path: str) -> NTDXLSXListTabsOperator:
        return NTDXLSXListTabsOperator(
            task_id="ntd_xlsx_list_tabs",
            gcp_conn_id="google_cloud_default",
            source_bucket=os.environ.get("CALITP_BUCKET__NTD_XLSX_DATA_PRODUCTS__RAW"),
            source_path=source_path,
            dag=test_dag,
        )

    @pytest.mark.vcr
    def test_execute(
        self,
        test_dag: DAG,
        operator: NTDXLSXListTabsOperator,
        execution_date: datetime,
        gcs_hook: GCSHook,
    ):
        operator.run(
            start_date=execution_date,
            end_date=execution_date + timedelta(days=1),
            ignore_first_depends_on_past=True,
        )

        task = test_dag.get_task("ntd_xlsx_list_tabs")
        task_instance = TaskInstance(task, execution_date=execution_date)
        xcom_value = task_instance.xcom_pull()
        assert xcom_value == [
            {
                "tab": "2022 Agency Information",
                "source_path": os.path.join(
                    "annual_database_agency_information_raw",
                    "2022",
                    "dt=2025-06-02",
                    "execution_ts=2025-06-02T00:00:00+00:00",
                    "2022__annual_database_agency_information_raw.xlsx",
                ),
            }
        ]
