import gzip
import json
import os
from datetime import datetime, timedelta, timezone

import pytest
from operators.kuba_to_gcs_operator import KubaToGCSOperator

from airflow.hooks.base import BaseHook
from airflow.models.connection import Connection
from airflow.models.dag import DAG
from airflow.models.taskinstance import TaskInstance
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class TestKubaToGCSOperator:
    @pytest.fixture
    def execution_date(self) -> datetime:
        return datetime.fromisoformat("2025-06-01").replace(tzinfo=timezone.utc)

    @pytest.fixture
    def gcs_hook(self) -> GCSHook:
        return GCSHook()

    @pytest.fixture
    def object_name(self) -> str:
        connection: Connection = BaseHook.get_connection("http_kuba")
        return f"device_properties/dt=2025-06-01/ts=2025-06-01T00:00:00+00:00/operator_identifier={connection.schema}/results.jsonl.gz"

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
    def operator(self, test_dag: DAG) -> KubaToGCSOperator:
        return KubaToGCSOperator(
            task_id="kuba_to_gcs",
            http_conn_id="http_kuba",
            gcp_conn_id="google_cloud_default",
            object_path="device_properties/dt=2025-06-01/ts=2025-06-01T00:00:00+00:00",
            endpoint="monitoring/deviceproperties/v1/ForLocations/all",
            parameters={"location_type": "1"},
            bucket=os.environ.get("CALITP_BUCKET__KUBA"),
            dag=test_dag,
        )

    @pytest.mark.vcr
    def test_execute(
        self,
        test_dag: DAG,
        operator: KubaToGCSOperator,
        execution_date: datetime,
        object_name: str,
        gcs_hook: GCSHook,
    ):
        operator.run(
            start_date=execution_date,
            end_date=execution_date + timedelta(hours=1) - timedelta(seconds=1),
            ignore_first_depends_on_past=True,
        )

        task = test_dag.get_task("kuba_to_gcs")
        task_instance = TaskInstance(task, execution_date=execution_date)
        xcom_value = task_instance.xcom_pull()
        assert xcom_value == os.path.join(
            os.environ.get("CALITP_BUCKET__KUBA"),
            "device_properties",
            "dt=2025-06-01",
            "ts=2025-06-01T00:00:00+00:00",
            "operator_identifier=66",
            "results.jsonl.gz",
        )

        compressed_result = gcs_hook.download(
            bucket_name=os.environ.get("CALITP_BUCKET__KUBA").replace("gs://", ""),
            object_name=object_name,
        )
        decompressed_result = gzip.decompress(compressed_result)
        results = [json.loads(x) for x in decompressed_result.splitlines()]

        assert results[0] == {
            "device": {
                "fo_device_logical_id": "66001",
                "fo_device_type": "Validator",
                "fo_device_type_model": "ABT3000",
                "fo_device_serial_number": "108008231118180362",
                "fo_device_description": "device 66001",
                "fo_device_location_id": "604",
                "fo_device_location": "604",
                "fo_device_last_connection": "2025-03-20T13:46:52.4000000Z",
            },
            "device_replicator_info": {
                "software_version": "1.2.3.4",
                "software_last_connection": None,
                "cd_version": "7",
                "cd_last_connection": "2025-03-20T12:55:50.3500000Z",
                "dataset_version": "0",
                "dataset_last_connection": None,
                "denylist_version": None,
                "denylist_last_connection": None,
                "acceptlist_version": "0",
                "acceptlist_last_connection": "2025-03-18T09:14:45.4070000Z",
                "binlist_version": "4589",
                "binlist_last_connection": "2025-03-20T08:30:45.4070000Z",
                "asset_last_connection": None,
                "monitoring_last_connection": None,
                "ud_last_transaction_time": "2025-03-20T13:46:52.4000000Z",
            },
            "device_monitor_info": {
                "application__isdisabled": "false",
                "application__isinservice": "true",
                "application__servicestatus": {"rows": []},
                "gps__position": results[0]["device_monitor_info"]["gps__position"]
                | {
                    "hasgpsfix": True,
                },
                "location__location__info": {
                    "current": {
                        "properties": {},
                        "stopinfo": {
                            "farematrixreference": 3,
                            "name": "Davis",
                            "reference": 3,
                            "type": 0,
                        },
                        "zoneinfo": {"name": "Davis", "reference": 3},
                    },
                    "dataversion": 0,
                    "locationprovidersource": "location::devicesettings::provider",
                    "properties": {},
                    "type": 65535,
                },
                "location__location__servicestatus": "Closed",
                "location__location__source": "location::ngwifi::provider",
                "ngwifi__gps__apistatus": {"status": 1},
                "ngwifi__gps__position": results[0]["device_monitor_info"][
                    "ngwifi__gps__position"
                ]
                | {
                    "success": True,
                },
                "os__uptime": "0 00:48:33.000",
                "smartmedium__emv3000__batterylevel": "3118",
            },
        }
