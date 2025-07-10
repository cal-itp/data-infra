import gzip
import json
import os
from datetime import datetime, timedelta, timezone

import pytest
from operators.aggregator_to_gcs_operator import (
    AggregatorObjectPath,
    MobilityDatabaseToGCSOperator,
)

from airflow.models.dag import DAG
from airflow.models.taskinstance import TaskInstance
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class TestMobilityDatabaseToGCSOperator:
    @pytest.fixture
    def execution_date(self) -> datetime:
        return datetime.fromisoformat("2025-06-01").replace(tzinfo=timezone.utc)

    @pytest.fixture
    def gcs_hook(self) -> GCSHook:
        return GCSHook()

    @pytest.fixture
    def object_path(self) -> AggregatorObjectPath:
        return AggregatorObjectPath("mobility_database")

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
    def operator(self, test_dag: DAG) -> MobilityDatabaseToGCSOperator:
        return MobilityDatabaseToGCSOperator(
            task_id="mobility_database_to_gcs",
            http_conn_id="http_mobility_database",
            gcp_conn_id="google_cloud_default",
            bucket=os.environ.get("CALITP_BUCKET__AGGREGATOR_SCRAPER"),
            dag=test_dag,
        )

    @pytest.mark.vcr
    def test_execute(
        self,
        test_dag: DAG,
        operator: MobilityDatabaseToGCSOperator,
        execution_date: datetime,
        object_path: AggregatorObjectPath,
        gcs_hook: GCSHook,
    ):
        operator.run(
            start_date=execution_date,
            end_date=execution_date + timedelta(hours=1) - timedelta(seconds=1),
            ignore_first_depends_on_past=True,
        )

        task = test_dag.get_task("mobility_database_to_gcs")
        task_instance = TaskInstance(task, execution_date=execution_date)
        xcom_value = task_instance.xcom_pull()
        assert xcom_value == os.path.join(
            os.environ.get("CALITP_BUCKET__AGGREGATOR_SCRAPER"),
            "gtfs_aggregator_scrape_results",
            "dt=2025-06-01",
            "ts=2025-06-01T00:00:00+00:00",
            "aggregator=mobility_database",
            "results.jsonl.gz",
        )

        compressed_result = gcs_hook.download(
            bucket_name=os.environ.get("CALITP_BUCKET__AGGREGATOR_SCRAPER").replace(
                "gs://", ""
            ),
            object_name=object_path.resolve(execution_date),
        )
        decompressed_result = gzip.decompress(compressed_result)
        result = [json.loads(x) for x in decompressed_result.splitlines()]
        assert "feed_url_str" in result[0]
        assert "key" in result[0]
        assert "raw_record" in result[0]
