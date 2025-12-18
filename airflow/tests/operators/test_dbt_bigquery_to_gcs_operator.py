import csv
import os
from datetime import datetime, timezone
from io import StringIO

import pytest
from dateutil.relativedelta import relativedelta
from operators.dbt_bigquery_to_gcs_operator import DBTBigQueryToGCSOperator

from airflow.models.dag import DAG
from airflow.models.taskinstance import TaskInstance
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class TestDBTBigQueryToGCSOperator:
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
        assert xcom_value == {
            "destination_path_prefix": os.path.join(
                os.environ.get("CALITP_BUCKET__PUBLISH"),
                "california_open_data__agency",
                "dt=2025-06-01",
                "ts=2025-06-01T00:00:00+00:00",
                "agency",
            )
        }

        result = gcs_hook.download(
            bucket_name=os.environ.get("CALITP_BUCKET__PUBLISH").replace("gs://", ""),
            object_name=os.path.join(
                "california_open_data__agency",
                "dt=2025-06-01",
                "ts=2025-06-01T00:00:00+00:00",
                "agency000000000000.csv",
            ),
        )

        f = StringIO(result.decode())
        reader = csv.DictReader(f)
        agencies = sorted(list(reader), key=lambda a: a["agency_id"])
        assert agencies[0] == agencies[0] | {
            "agency_lang": "en",
            "agency_name": "National Park Service",
            "agency_timezone": "America/Los_Angeles",
            "agency_url": "https://www.nps.gov/yose/planyourvisit/publictransportation.htm",
            "base64_url": "aHR0cHM6Ly93d3cubnBzLmdvdi9leHRlcm5hbC1yZXNvdXJjZXMvZ3Rmcy95b3NlL3lvc2VtaXRlLXZhbGxleS1zaHV0dGxlLnppcA==",
        }
