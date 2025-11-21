import os
from datetime import datetime, timedelta, timezone

import pytest
from operators.ntd_xlsx_to_gcs_operator import NTDXLSXToGCSOperator

from airflow.models.dag import DAG
from airflow.models.taskinstance import TaskInstance
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class TestNTDXLSXToGCSOperator:
    @pytest.fixture
    def execution_date(self) -> datetime:
        return datetime.fromisoformat("2025-06-02").replace(tzinfo=timezone.utc)

    @pytest.fixture
    def gcs_hook(self) -> GCSHook:
        return GCSHook()

    @pytest.fixture
    def source_url(self) -> str:
        return "/ntd/data-product/2022-annual-database-agency-information"

    @pytest.fixture
    def destination_path(self) -> str:
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
    def operator(
        self, test_dag: DAG, destination_path: str, source_url: str
    ) -> NTDXLSXToGCSOperator:
        return NTDXLSXToGCSOperator(
            task_id="ntd_xlsx_to_gcs",
            gcp_conn_id="google_cloud_default",
            http_conn_id="http_dot",
            source_url=source_url,
            destination_bucket=os.environ.get(
                "CALITP_BUCKET__NTD_XLSX_DATA_PRODUCTS__RAW"
            ),
            destination_path=destination_path,
            dag=test_dag,
        )

    @pytest.mark.vcr
    def test_execute(
        self,
        test_dag: DAG,
        operator: NTDXLSXToGCSOperator,
        execution_date: datetime,
        gcs_hook: GCSHook,
    ):
        operator.run(
            start_date=execution_date,
            end_date=execution_date + timedelta(days=1),
            ignore_first_depends_on_past=True,
        )

        task = test_dag.get_task("ntd_xlsx_to_gcs")
        task_instance = TaskInstance(task, execution_date=execution_date)
        xcom_value = task_instance.xcom_pull()
        assert xcom_value == {
            "resolved_url": "/sites/fta.dot.gov/files/2024-07/2022%20Agency%20Information_1-3_0.xlsx",
            "destination_path": os.path.join(
                "annual_database_agency_information_raw",
                "2022",
                "dt=2025-06-02",
                "execution_ts=2025-06-02T00:00:00+00:00",
                "2022__annual_database_agency_information_raw.xlsx",
            ),
        }

        result = gcs_hook.download(
            bucket_name=os.environ.get(
                "CALITP_BUCKET__NTD_XLSX_DATA_PRODUCTS__RAW"
            ).replace("gs://", ""),
            object_name=xcom_value["destination_path"],
        )
        assert len(result) > 0
