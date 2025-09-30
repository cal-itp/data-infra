import os
from datetime import datetime, timezone
from io import StringIO
import csv

import pytest
from dateutil.relativedelta import relativedelta
from operators.dbt_exposure_metadata_to_gcs_operator import DbtExposureMetadataToGcsOperator

from airflow.models.dag import DAG
from airflow.models.taskinstance import TaskInstance
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class TestDbtExposureMetadataToGcsOperator:
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
    def operator(self, test_dag: DAG) -> DbtExposureMetadataToGcsOperator:
        return DbtExposureMetadataToGcsOperator(
            task_id="dbt_metadata_manifest_to_gcs",
            gcp_conn_id="google_cloud_default",
            source_bucket_name=os.environ.get("CALITP_BUCKET__DBT_DOCS"),
            source_object_name="manifest.json",
            destination_bucket_name=os.environ.get("CALITP_BUCKET__PUBLISH"),
            destination_object_name=os.path.join(
                "california_open_data__metadata",
                "dt=2025-06-01",
                "ts=2025-06-01T00:00:00+00:00",
                "metadata.csv",
            ),
            dag=test_dag,
        )

    @pytest.mark.vcr
    def test_execute(
        self,
        test_dag: DAG,
        operator: DbtExposureMetadataToGcsOperator,
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

        task = test_dag.get_task("dbt_metadata_manifest_to_gcs")
        task_instance = TaskInstance(task, execution_date=execution_date)
        xcom_value = task_instance.xcom_pull()
        assert xcom_value == os.path.join(
            os.environ.get("CALITP_BUCKET__PUBLISH"),
            "california_open_data__metadata",
            "dt=2025-06-01",
            "ts=2025-06-01T00:00:00+00:00",
            "metadata.csv"
        )

        result = gcs_hook.download(
            bucket_name=os.environ.get("CALITP_BUCKET__PUBLISH").replace(
                "gs://", ""
            ),
            object_name=os.path.join(
                "california_open_data__metadata",
                "dt=2025-06-01",
                "ts=2025-06-01T00:00:00+00:00",
                "metadata.csv"
            )
        )

        f = StringIO(result.decode("utf-8"))
        reader = csv.DictReader(f, delimiter="\t")
        assert list(reader)[0] == {
            "ACCESS_CONSTRAINTS": "",
            "CALTRANS_LINK": "",
            "CONTACT_EMAIL": "hunter.owens@dot.ca.gov",
            "CONTACT_NAME": "Hunter Owens",
            "CONTACT_ORGANIZATION": "Caltrans",
            "CONTACT_POSITION": "Cal-ITP",
            "CREATION_DATE": "2025-06-01T00:00:00+00:00",
            "DATASET_NAME": "agency",
            "DATA_DICTIONARY": "",
            "DATA_DICTIONARY_TYPE": "csv",
            "DATA_LIFE_SPAN": "",
            "DATA_STANDARD": "https://gtfs.org/schedule/",
            "DESCRIPTION": "Each row is a cleaned row from an agency.txt file. Definitions for the original GTFS fields are available at: https://gtfs.org/reference/static#agencytxt.",
            "FREQUENCY": "Monthly",
            "GIS_COORDINATE_SYSTEM_EPSG": "4326",
            "GIS_HORIZ_ACCURACY": "4m",
            "GIS_THEME": "",
            "GIS_VERT_ACCURACY": "4m",
            "GIS_VERT_DATUM_EPSG": "",
            "LAST_UPDATE": "",
            "METHODOLOGY": "Cal-ITP collects the GTFS feeds from a statewide list every night and aggegrates it into a statewide table for analysis purposes only. Do not use for trip planner ingestion, rather is meant to be used for statewide analytics and other use cases. Note: These data may or may or may not have passed GTFS-Validation.",
            "NEXT_UPDATE": "2025-07-01T00:00:00+00:00",
            "NOTES": "",
            "PLACE": "CA",
            "PUBLIC_ACCESS_LEVEL": "Public",
            "PUBLISHER_ORGANIZATION": "Caltrans",
            "STATUS": "Complete",
            "TAGS": "transit,gtfs,gtfs-schedule,bus,rail,ferry,mobility",
            "TEMPORAL_COVERAGE_BEGIN": "",
            "TEMPORAL_COVERAGE_END": "",
            "TOPIC": "Transportation",
            "USE_CONSTRAINTS": "Creative Commons 4.0 Attribution",
        }
