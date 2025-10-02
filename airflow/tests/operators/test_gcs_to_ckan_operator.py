import os
from datetime import datetime, timezone

import pytest
from dateutil.relativedelta import relativedelta
from operators.gcs_to_ckan_operator import GCSToCKANOperator

from airflow.models.dag import DAG
from airflow.models.taskinstance import TaskInstance
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class TestGCSToCKANOperator:
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
    def operator(self, test_dag: DAG) -> GCSToCKANOperator:
        return GCSToCKANOperator(
            task_id="gcs_to_ckan",
            gcp_conn_id="google_cloud_default",
            bucket_name=os.environ.get("CALITP_BUCKET__PUBLISH"),
            object_name=os.path.join(
                "california_open_data__metadata",
                "dt=2025-06-01",
                "ts=2025-06-01T00:00:00+00:00",
                "metadata.csv",
            ),
            resource_id="bedac9e4-4fce-4287-bf60-0064ddaf999c",
            ckan_conn_id="http_ckan",
            dag=test_dag,
        )

    @pytest.mark.vcr
    def test_execute(
        self,
        test_dag: DAG,
        operator: GCSToCKANOperator,
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

        task = test_dag.get_task("gcs_to_ckan")
        task_instance = TaskInstance(task, execution_date=execution_date)
        xcom_value = task_instance.xcom_pull()
        assert (
            xcom_value
            == {
                "cache_last_updated": None,
                "cache_url": None,
                "ckan_url": "https://test-data.technology.ca.gov",
                "datastore_active": True,
                "datastore_contains_all_records_of_source_file": True,
                "description": "",
                "format": "CSV",
                "hash": "540ff57f389d699ed027208e2eba76a8",
                "id": "bedac9e4-4fce-4287-bf60-0064ddaf999c",
                "ignore_hash": False,
                "is_data_dict_populated": False,
                "mimetype": None,
                "mimetype_inner": None,
                "name": "Metadata",
                "original_url": "https://test-data.technology.ca.gov/dataset/ba2a80ce-2065-427b-a8fb-8e5bed44cfc3/resource/bedac9e4-4fce-4287-bf60-0064ddaf999c/download/upload",
                "package_id": "ba2a80ce-2065-427b-a8fb-8e5bed44cfc3",
                "position": 0,
                "resource_type": None,
                "set_url_type": False,
                "size": 19269,
                "state": "active",
                "url": "https://test-data.technology.ca.gov/dataset/ba2a80ce-2065-427b-a8fb-8e5bed44cfc3/resource/bedac9e4-4fce-4287-bf60-0064ddaf999c/download/upload",
                "url_type": "upload",
            }
            | xcom_value
        )
