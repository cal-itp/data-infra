import gzip
import json
import os
from datetime import datetime, timedelta, timezone

import pytest
from hooks.airtable_hook import AirtableHook
from operators.airtable_to_gcs_operator import AirtableObjectPath, AirtableToGCSOperator

from airflow.models.dag import DAG
from airflow.models.taskinstance import TaskInstance
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class TestAirtableToGCSOperator:
    @pytest.fixture
    def execution_date(self) -> datetime:
        return datetime.fromisoformat("2025-06-01").replace(tzinfo=timezone.utc)

    @pytest.fixture
    def gcs_hook(self) -> GCSHook:
        return GCSHook()

    @pytest.fixture
    def airtable_hook(self) -> AirtableHook:
        return AirtableHook()

    @pytest.fixture
    def object_path(self) -> AirtableObjectPath:
        return AirtableObjectPath("california_transit", "gtfs datasets")

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
    def operator(self, test_dag: DAG) -> AirtableToGCSOperator:
        return AirtableToGCSOperator(
            task_id="airtable_to_gcs",
            airtable_conn_id="airtable_default",
            air_base_id="appPnJWrQ7ui4UmIl",
            air_base_name="california_transit",
            air_table_name="gtfs datasets",
            gcp_conn_id="google_cloud_default",
            bucket=os.environ.get("CALITP_BUCKET__AIRTABLE"),
            dag=test_dag,
        )

    @pytest.mark.vcr
    def test_execute(
        self,
        test_dag: DAG,
        operator: AirtableToGCSOperator,
        execution_date: datetime,
        object_path: AirtableObjectPath,
        gcs_hook: GCSHook,
        airtable_hook: AirtableHook,
    ):
        operator.run(
            start_date=execution_date,
            end_date=execution_date + timedelta(days=1),
            ignore_first_depends_on_past=True,
        )

        task = test_dag.get_task("airtable_to_gcs")
        task_instance = TaskInstance(task, execution_date=execution_date)
        xcom_value = task_instance.xcom_pull()
        assert xcom_value == os.path.join(
            os.environ.get("CALITP_BUCKET__AIRTABLE"),
            "california_transit__gtfs_datasets",
            "dt=2025-06-01",
            "ts=2025-06-01T00:00:00+00:00",
            "gtfs_datasets.jsonl.gz",
        )

        compressed_result = gcs_hook.download(
            bucket_name=os.environ.get("CALITP_BUCKET__AIRTABLE").replace("gs://", ""),
            object_name=object_path.resolve(execution_date),
        )
        decompressed_result = gzip.decompress(compressed_result)
        result = [json.loads(x) for x in decompressed_result.splitlines()]

        airtable_rows = airtable_hook.read(
            air_base_id="appPnJWrQ7ui4UmIl",
            air_table_name="gtfs datasets",
        )
        assert result[0]["id"] == airtable_rows[0]["id"]
        for key, _ in airtable_rows[0]["fields"].items():
            assert (
                key.lower()
                .replace(" ", "_")
                .replace("(", "_")
                .replace(")", "_")
                .replace(":", "_")
                .replace("-", "_")
                in result[0]
            )
