import os
from datetime import datetime, timezone
from io import StringIO
import csv

import pytest
from dateutil.relativedelta import relativedelta
from operators.dbt_manifest_to_metadata_operator import DBTManifestToMetadataOperator

from airflow.models.dag import DAG
from airflow.models.taskinstance import TaskInstance
from airflow.providers.google.cloud.hooks.gcs import GCSHook


class TestDBTManifestToMetadataOperator:
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
    def operator(self, test_dag: DAG) -> DBTManifestToMetadataOperator:
        return DBTManifestToMetadataOperator(
            task_id="dbt_manifest_to_metadata",
            gcp_conn_id="google_cloud_default",
            bucket_name=os.environ.get("CALITP_BUCKET__DBT_DOCS"),
            object_name="manifest.json",
            dag=test_dag,
        )

    @pytest.mark.vcr
    def test_execute(
        self,
        test_dag: DAG,
        operator: DBTManifestToMetadataOperator,
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

        task = test_dag.get_task("dbt_manifest_to_metadata")
        task_instance = TaskInstance(task, execution_date=execution_date)
        xcom_value = task_instance.xcom_pull()
        assert xcom_value["c3828596-e796-4b3b-a146-ebeb09b3a4d2"] == {
            "ACCESS_CONSTRAINTS": None,
            "CALTRANS_LINK": None,
            "CONTACT_EMAIL": "hunter.owens@dot.ca.gov",
            "CONTACT_NAME": "Hunter Owens",
            "CONTACT_ORGANIZATION": "Caltrans",
            "CONTACT_POSITION": "Cal-ITP",
            "CREATION_DATE": "2025-06-01T00:00:00+00:00",
            "DATASET_NAME": "agency",
            "DATA_DICTIONARY": "",
            "DATA_DICTIONARY_TYPE": "csv",
            "DATA_LIFE_SPAN": None,
            "DATA_STANDARD": "https://gtfs.org/schedule/",
            "DESCRIPTION": "Each row is a cleaned row from an agency.txt file. Definitions for the original GTFS fields are available at: https://gtfs.org/reference/static#agencytxt.",
            "FREQUENCY": "Monthly",
            "GIS_COORDINATE_SYSTEM_EPSG": "4326",
            "GIS_HORIZ_ACCURACY": "4m",
            "GIS_THEME": None,
            "GIS_VERT_ACCURACY": "4m",
            "GIS_VERT_DATUM_EPSG": None,
            "LAST_UPDATE": None,
            "METHODOLOGY": "Cal-ITP collects the GTFS feeds from a statewide list every night and aggegrates it into a statewide table for analysis purposes only. Do not use for trip planner ingestion, rather is meant to be used for statewide analytics and other use cases. Note: These data may or may or may not have passed GTFS-Validation.",
            "NEXT_UPDATE": "2025-07-01T00:00:00+00:00",
            "NOTES": None,
            "PLACE": "CA",
            "PUBLIC_ACCESS_LEVEL": "Public",
            "PUBLISHER_ORGANIZATION": "Caltrans",
            "STATUS": "Complete",
            "TAGS": "transit,gtfs,gtfs-schedule,bus,rail,ferry,mobility",
            "TEMPORAL_COVERAGE_BEGIN": None,
            "TEMPORAL_COVERAGE_END": None,
            "TOPIC": "Transportation",
            "USE_CONSTRAINTS": "Creative Commons 4.0 Attribution",
        }
