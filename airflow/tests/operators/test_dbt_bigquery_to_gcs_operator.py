import gzip
import json
import os
from datetime import datetime, timezone

import pytest
from dateutil.relativedelta import relativedelta
from operators.dbt_bigquery_to_gcs_operator import DBTBigQueryToGCSOperator

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
    def operator(self, test_dag: DAG) -> DBTBigQueryToGCSOperator:
        return DBTBigQueryToGCSOperator(
            task_id="dbt_bigquery_to_gcs",
            gcp_conn_id="google_cloud_default",
            source_bucket_name=os.environ.get("CALITP_BUCKET__DBT_DOCS"),
            source_object_name="manifest.json",
            destination_bucket_name=os.environ.get("CALITP_BUCKET__PUBLISH"),
            destination_object_name=os.path.join(
                "california_open_data__agency",
                "dt=2025-06-01",
                "ts=2025-06-01T00:00:00+00:00",
                "agency.csv",
            ),
            table_name="agency",
            dag=test_dag,
        )

    @pytest.mark.vcr
    def test_execute(
        self,
        test_dag: DAG,
        operator: DBTBigQueryToGCSOperator,
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

        task = test_dag.get_task("dbt_bigquery_to_gcs")
        task_instance = TaskInstance(task, execution_date=execution_date)
        xcom_value = task_instance.xcom_pull()
        assert (
            os.path.join(
                os.environ.get("CALITP_BUCKET__PUBLISH"),
                "california_open_data__agency",
                "dt=2025-06-01",
                "ts=2025-06-01T00:00:00+00:00",
                "agency.csv",
            )
            in xcom_value
        )

        result = gcs_hook.download(
            bucket_name=os.environ.get("CALITP_BUCKET__NTD_API_DATA_PRODUCTS").replace(
                "gs://", ""
            ),
            object_name=os.path.join(
                "california_open_data__agency",
                "dt=2025-06-01",
                "ts=2025-06-01T00:00:00+00:00",
                "agency.csv",
            )
        )

        f = StringIO(result.decode())
        reader = csv.DictReader(f, delimiter="\t")
        assert list(reader) == [{"testing": "stuff"}]
