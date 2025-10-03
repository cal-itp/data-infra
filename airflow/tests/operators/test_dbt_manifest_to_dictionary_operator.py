import os
from datetime import datetime, timezone

import pytest
from dateutil.relativedelta import relativedelta
from operators.dbt_manifest_to_dictionary_operator import DBTManifestToDictionaryOperator

from airflow.models.dag import DAG
from airflow.models.taskinstance import TaskInstance
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class TestDBTManifestToDictionaryOperator:
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
    def operator(self, test_dag: DAG) -> DBTManifestToDictionaryOperator:
        return DBTManifestToDictionaryOperator(
            task_id="dbt_manifest_to_dictionary",
            gcp_conn_id="google_cloud_default",
            bucket_name=os.environ.get("CALITP_BUCKET__DBT_DOCS"),
            object_name="manifest.json",
            dag=test_dag,
        )

    @pytest.mark.vcr
    def test_execute(
        self,
        test_dag: DAG,
        operator: DBTManifestToDictionaryOperator,
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

        task = test_dag.get_task("dbt_manifest_to_dictionary")
        task_instance = TaskInstance(task, execution_date=execution_date)
        xcom_value = task_instance.xcom_pull()
        assert xcom_value[0] == {
            'ALLOWABLE_MAX_VALUE': None,
            'ALLOWABLE_MIN_VALUE': None,
            'CONFIDENTIAL': 'N',
            'DOMAIN_TYPE': 'Unrepresented',
            'FIELD_ALIAS': None,
            'FIELD_DESCRIPTION': 'Base 64 encoded URL from which this data was scraped.\n',
            'FIELD_DESCRIPTION_AUTHORITY': 'https://gtfs.org/schedule/reference/#agencytxt',
            'FIELD_LENGTH': 1024,
            'FIELD_NAME': 'base64_url',
            'FIELD_PRECISION': None,
            'FIELD_TYPE': 'STRING',
            'PCI': 'N',
            'PII': 'N',
            'SENSITIVE': 'N',
            'SYSTEM_NAME': 'Cal-ITP GTFS-Ingest Pipeline',
            'TABLE_NAME': 'agency',
            'UNITS': None,
            'USAGE_NOTES': None
        }
