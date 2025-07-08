import gzip
import json
import os
from datetime import datetime, timezone

import pytest
from dateutil.relativedelta import relativedelta
from operators.ntd_to_gcs_operator import NTDObjectPath, NTDToGCSOperator

from airflow.models.dag import DAG
from airflow.models.taskinstance import TaskInstance
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class TestNTDToGCSOperator:
    @pytest.fixture
    def execution_date(self) -> datetime:
        return datetime.fromisoformat("2025-06-01").replace(tzinfo=timezone.utc)

    @pytest.fixture
    def gcs_hook(self) -> GCSHook:
        return GCSHook()

    @pytest.fixture
    def object_path(self) -> NTDObjectPath:
        return NTDObjectPath(
            product="operating_expenses_by_type_and_agency", year="multi_year"
        )

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
    def operator(self, test_dag: DAG) -> NTDToGCSOperator:
        return NTDToGCSOperator(
            task_id="ntd_to_gcs",
            http_conn_id="http_ntd",
            gcp_conn_id="google_cloud_default",
            bucket=os.environ.get("CALITP_BUCKET__NTD_API_DATA_PRODUCTS"),
            product="operating_expenses_by_type_and_agency",
            year="multi_year",
            endpoint="resource/i4ua-cjx4.json",
            parameters={"$limit": 10},
            dag=test_dag,
        )

    @pytest.mark.vcr
    def test_execute(
        self,
        test_dag: DAG,
        operator: NTDToGCSOperator,
        execution_date: datetime,
        object_path: NTDObjectPath,
        gcs_hook: GCSHook,
    ):
        operator.run(
            start_date=execution_date,
            end_date=execution_date
            + relativedelta(months=+1)
            - relativedelta(seconds=-1),
            ignore_first_depends_on_past=True,
        )

        task = test_dag.get_task("ntd_to_gcs")
        task_instance = TaskInstance(task, execution_date=execution_date)
        xcom_value = task_instance.xcom_pull()
        assert xcom_value == os.path.join(
            os.environ.get("CALITP_BUCKET__NTD_API_DATA_PRODUCTS"),
            "operating_expenses_by_type_and_agency",
            "multi_year",
            "dt=2025-06-01",
            "execution_ts=2025-06-01T00:00:00+00:00",
            "multi_year__operating_expenses_by_type_and_agency.jsonl.gz",
        )

        compressed_result = gcs_hook.download(
            bucket_name=os.environ.get("CALITP_BUCKET__NTD_API_DATA_PRODUCTS").replace(
                "gs://", ""
            ),
            object_name=object_path.resolve(execution_date),
        )
        decompressed_result = gzip.decompress(compressed_result)
        result = [json.loads(x) for x in decompressed_result.splitlines()]
        assert "max_agency" in result[0]
