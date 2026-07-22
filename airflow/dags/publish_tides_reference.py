import os
from datetime import datetime, timedelta

from dags import email_on_failure, log_failure_to_slack
from operators.dbt_manifest_to_models_operator import DBTManifestToModelsOperator
from operators.tides_dcat_metadata_operator import TIDESDCATMetadataOperator
from operators.tides_frictionless_metadata_operator import (
    TIDESFrictionlessMetadataOperator,
)
from operators.tides_reference_export_operator import (
    TIDESReferenceExportOperator,
    reference_destination_prefix,
)

from airflow.decorators import dag
from airflow.operators.latest_only import LatestOnlyOperator


@dag(
    # Every Monday at 4pm Pacific (midnight UTC Tuesday), after the dbt_all
    # runs -- same cadence as publish_gtfs
    schedule="0 0 * * 2",
    start_date=datetime(2026, 7, 16),
    catchup=False,
    tags=["tides", "open-data"],
    default_args={
        "email": os.getenv("CALITP_NOTIFY_EMAIL"),
        "email_on_failure": email_on_failure(),
        "email_on_retry": False,
        "on_failure_callback": log_failure_to_slack,
    },
)
def publish_tides_reference():
    """Publishes the TIDES reference tables to the TIDES bucket.

    The tables that resolve the opaque IDs on the published TIDES facts
    (organizations, provider_gtfs_data, gtfs_datasets, services, agency) are
    modeled as dbt models tagged `tides_reference` (warehouse/models/mart/
    tides). This DAG discovers the tagged models from the dbt manifest and
    exports each one in full to the TIDES bucket as parquet + CSV:

      * *_latest models  -> reference/<model>/ (stable path, overwritten)
      * history models   -> reference/<model>/dt=<run date>/

    Machine-readable metadata (SAM 5160.1) is published in the same run: a
    Frictionless datapackage.json next to each exported table, and a DCAT-US
    data.json catalog covering the reference tables plus the fact tables.
    """
    latest_only = LatestOnlyOperator(task_id="latest_only", depends_on_past=False)

    reference_models = DBTManifestToModelsOperator(
        task_id="list_reference_models",
        bucket_name=os.getenv("CALITP_BUCKET__DBT_DOCS"),
        object_name="manifest.json",
        tag="tides_reference",
    )

    def create_export_kwargs(model):
        return {
            "dataset_name": model["schema"],
            "table_name": model["name"],
            "destination_path_prefix": reference_destination_prefix(
                model["name"], "{{ ds }}"
            ),
            "report_path": (
                "reference_outcomes/dt={{ ds }}/ts={{ ts }}/"
                f"{model['name']}_outcomes.jsonl"
            ),
        }

    export_reference_models = TIDESReferenceExportOperator.partial(
        task_id="export_reference_models",
        retries=1,
        retry_delay=timedelta(seconds=10),
        ts="{{ ts }}",
        destination_bucket=os.environ.get("CALITP_BUCKET__TIDES"),
        user_project=os.environ.get("GOOGLE_CLOUD_PROJECT"),
        map_index_template="{{ task.table_name }}",
    ).expand_kwargs(reference_models.output.map(create_export_kwargs))

    def create_datapackage_kwargs(model):
        return {
            "model_name": model["name"],
            "destination_path_prefix": reference_destination_prefix(
                model["name"], "{{ ds }}"
            ),
        }

    write_datapackages = TIDESFrictionlessMetadataOperator.partial(
        task_id="write_datapackages",
        retries=1,
        retry_delay=timedelta(seconds=10),
        bucket_name=os.getenv("CALITP_BUCKET__DBT_DOCS"),
        destination_bucket=os.environ.get("CALITP_BUCKET__TIDES"),
        user_project=os.environ.get("GOOGLE_CLOUD_PROJECT"),
        map_index_template="{{ task.model_name }}",
    ).expand_kwargs(reference_models.output.map(create_datapackage_kwargs))

    write_dcat_catalog = TIDESDCATMetadataOperator(
        task_id="write_dcat_catalog",
        retries=1,
        retry_delay=timedelta(seconds=10),
        bucket_name=os.getenv("CALITP_BUCKET__DBT_DOCS"),
        models=reference_models.output,
        extra_datasets=[
            {
                "model_name": "fct_tides_vehicle_locations",
                "prefix": "vehicle_locations/",
                "formats": ["parquet"],
            },
            {
                "model_name": "fct_tides_trips_performed",
                "prefix": "trips_performed/",
                "formats": ["parquet"],
            },
        ],
        destination_bucket=os.environ.get("CALITP_BUCKET__TIDES"),
        user_project=os.environ.get("GOOGLE_CLOUD_PROJECT"),
    )

    latest_only >> reference_models
    export_reference_models >> write_datapackages
    export_reference_models >> write_dcat_catalog


publish_tides_reference = publish_tides_reference()
