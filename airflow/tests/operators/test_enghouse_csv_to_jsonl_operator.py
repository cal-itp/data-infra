import gzip
import json
import os
from datetime import datetime, timedelta, timezone

import pytest
from operators.enghouse_csv_to_jsonl_operator import EnghouseCSVToJSONLOperator

from airflow.models.dag import DAG
from airflow.models.taskinstance import TaskInstance
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class TestEnghouseCSVToJSONLOperator:
    @pytest.fixture
    def execution_date(self) -> datetime:
        return datetime.fromisoformat("2026-03-21").replace(tzinfo=timezone.utc)

    @pytest.fixture
    def gcs_hook(self) -> GCSHook:
        return GCSHook()

    @pytest.fixture
    def parsed_bucket(self) -> str:
        return os.environ.get("CALITP_BUCKET__ENGHOUSE_PARSED").replace("gs://", "")

    @pytest.fixture
    def source_path(self) -> str:
        return "pw/camarillo/pw_camarillo_pay-window-2026-03-20.csv"

    @pytest.fixture
    def destination_path(self) -> str:
        return "pw/agency=camarillo/dt=2026-03-20/pw_camarillo_pay-window-2026-03-20.jsonl.gz"

    @pytest.fixture
    def audit_path(self) -> str:
        return "enghouse_parse_job_results/agency=camarillo/dt=2026-03-20/pw_camarillo_pay-window-2026-03-20.jsonl"

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
    def operator(self, test_dag: DAG) -> EnghouseCSVToJSONLOperator:
        return EnghouseCSVToJSONLOperator(
            task_id="enghouse_csv_to_jsonl",
            gcp_conn_id="google_cloud_default",
            dag=test_dag,
        )

    @pytest.mark.vcr
    def test_execute(
        self,
        test_dag: DAG,
        operator: EnghouseCSVToJSONLOperator,
        execution_date: datetime,
        gcs_hook: GCSHook,
        parsed_bucket: str,
        source_path: str,
        destination_path: str,
        audit_path: str,
    ):
        operator.run(
            start_date=execution_date,
            end_date=execution_date + timedelta(days=1),
            ignore_first_depends_on_past=True,
        )

        task = test_dag.get_task("enghouse_csv_to_jsonl")
        task_instance = TaskInstance(task, execution_date=execution_date)
        xcom_value = task_instance.xcom_pull()
        assert xcom_value == {"processed": 1, "skipped": 0, "errors": 0}

        compressed_result = gcs_hook.download(
            bucket_name=parsed_bucket,
            object_name=destination_path,
        )
        decompressed_result = gzip.decompress(compressed_result)
        result = [json.loads(x) for x in decompressed_result.splitlines()]
        assert result[0] == {
            "id": "00000000-0000-0000-0000-000000000001",
            "token": "TOKEN00000000000000000000000000000000000000000000000000000000001",
            "amount_settled": "0",
            "amount_to_settle": "0",
            "debt_settled": "0",
            "stage": "Open",
            "payment_reference": "9000000001",
            "terminal_id": "78001",
            "open_date": "2026-03-20T19:10:22",
            "operator_id": "277",
            "_line_number": 1,
        }

        audit_result = json.loads(
            gcs_hook.download(bucket_name=parsed_bucket, object_name=audit_path)
        )
        assert audit_result["raw"]["agency"] == "camarillo"
        assert audit_result["raw"]["path"] == source_path
        assert audit_result["raw"]["size"] == 1308
        assert audit_result["parsed"]["agency"] == "camarillo"
        assert audit_result["parsed"]["path"] == destination_path
        assert audit_result["parsed"]["size"] == len(compressed_result)
