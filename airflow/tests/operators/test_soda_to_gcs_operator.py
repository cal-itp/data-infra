import gzip
import json
import os
from datetime import datetime, timezone

import pytest
from dateutil.relativedelta import relativedelta
from operators.soda_to_gcs_operator import SODAToGCSOperator

from airflow.models.dag import DAG
from airflow.models.taskinstance import TaskInstance
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class TestSODAToGCSOperator:
    @pytest.fixture
    def execution_date(self) -> datetime:
        return datetime.fromisoformat("2025-06-01").replace(tzinfo=timezone.utc)

    @pytest.fixture
    def gcs_hook(self) -> GCSHook:
        return GCSHook()

    @pytest.fixture
    def test_dag(self, execution_date: datetime) -> DAG:
        return DAG(
            "test_dag",
            default_args={
                "owner": "airflow",
                "start_date": execution_date,
                "end_date": execution_date + relativedelta(months=+1),
            },
            schedule=relativedelta(months=+1),
        )

    @pytest.fixture
    def operator(self, test_dag: DAG) -> SODAToGCSOperator:
        return SODAToGCSOperator(
            task_id="soda_to_gcs",
            http_conn_id="http_ntd",
            gcp_conn_id="google_cloud_default",
            bucket_name=os.environ.get("CALITP_BUCKET__NTD_API_DATA_PRODUCTS"),
            object_path="operating_expenses_by_type_and_agency/multi_year/dt=2025-06-01/execution_ts=2025-06-01T00:00:00+00:00",
            resource="i4ua-cjx4",
            dag=test_dag,
        )

    @pytest.mark.vcr
    def test_execute(
        self,
        test_dag: DAG,
        operator: SODAToGCSOperator,
        execution_date: datetime,
        gcs_hook: GCSHook,
    ):
        operator.run(
            start_date=execution_date,
            end_date=execution_date
            + relativedelta(months=+1)
            - relativedelta(seconds=-1),
            ignore_first_depends_on_past=True,
        )

        task = test_dag.get_task("soda_to_gcs")
        task_instance = TaskInstance(task, execution_date=execution_date)
        xcom_value = task_instance.xcom_pull()
        assert (
            os.path.join(
                os.environ.get("CALITP_BUCKET__NTD_API_DATA_PRODUCTS"),
                "operating_expenses_by_type_and_agency",
                "multi_year",
                "dt=2025-06-01",
                "execution_ts=2025-06-01T00:00:00+00:00",
                "page-0001.jsonl.gz",
            )
            in xcom_value
        )

        compressed_result = gcs_hook.download(
            bucket_name=os.environ.get("CALITP_BUCKET__NTD_API_DATA_PRODUCTS").replace(
                "gs://", ""
            ),
            object_name="operating_expenses_by_type_and_agency/multi_year/dt=2025-06-01/execution_ts=2025-06-01T00:00:00+00:00/page-0001.jsonl.gz",
        )
        decompressed_result = gzip.decompress(compressed_result)
        result = [json.loads(x) for x in decompressed_result.splitlines()]
        assert result[0] == {
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
