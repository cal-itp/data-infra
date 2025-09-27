import os
from datetime import datetime, timezone
from io import StringIO
import csv

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
            bucket=os.environ.get("CALITP_BUCKET__PUBLISH"),
            object_name=os.path.join(
                "california_open_data__metadata",
                "dt=2025-06-01",
                "ts=2025-06-01T00:00:00+00:00",
                "metadata.csv"
            ),
            resource_id="53c05c25-e467-407a-bb29-303875215adc",
            ckan_conn_id="ckan_default",
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

class TestBigqueryToCKANOperator:
    def test_execute(self):
        user_agent = "ckanapi/1.0 (+https://dds.dot.ca.gov)"
        apikey = os.environ.get("CKAN_API_KEY")
        ckan = RemoteCKAN("https://data.ca.gov", apikey=apikey, user_agent=user_agent)
        package_info = ckan.call_action(
            "package_show", {"id": "cal-itp-gtfs-ingest-pipeline-dataset"}
        )
        assert "resources" in package_info

        resource = ckan.call_action(
            "resource_show", {"id": "c3828596-e796-4b3b-a146-ebeb09b3a4d2"}
        )
        assert resource == {
            "cache_last_updated": None,
            "cache_url": None,
            "created": "2023-07-05T20:08:39.731815",
            "datastore_active": True,
            "datastore_contains_all_records_of_source_file": True,
            "format": "CSV",
            "hash": "0c0700cb7ad3c40980ce5a476ae27dc3",
            "id": "c3828596-e796-4b3b-a146-ebeb09b3a4d2",
            "last_modified": "2025-07-14T00:22:18.044402",
            "metadata_modified": "2025-07-14T00:22:23.389548",
            "mimetype": None,
            "mimetype_inner": None,
            "name": "agency",
            "package_id": "de6f1544-b162-4d16-997b-c183912c8e62",
            "position": 2,
            "resource_id": "c3828596-e796-4b3b-a146-ebeb09b3a4d2",
            "resource_type": None,
            "size": None,
            "state": "active",
            "url": "https://data.ca.gov/dataset/de6f1544-b162-4d16-997b-c183912c8e62/resource/c3828596-e796-4b3b-a146-ebeb09b3a4d2/download/agency.csv",
            "url_type": "upload",
        }
