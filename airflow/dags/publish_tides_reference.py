import os
from datetime import datetime, timedelta

from dags import email_on_failure, log_failure_to_slack
from operators.dbt_manifest_to_models_operator import DBTManifestToModelsOperator
from operators.tides_reference_export_operator import TIDESReferenceExportOperator

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
    """
    latest_only = LatestOnlyOperator(task_id="latest_only", depends_on_past=False)

    reference_models = DBTManifestToModelsOperator(
        task_id="list_reference_models",
        bucket_name=os.getenv("CALITP_BUCKET__DBT_DOCS"),
        object_name="manifest.json",
        tag="tides_reference",
    )

    def create_export_kwargs(model):
        if model["name"].endswith("_latest"):
            destination_path_prefix = os.path.join("reference", model["name"]) + "/"
        else:
            destination_path_prefix = (
                os.path.join("reference", model["name"], "dt={{ ds }}") + "/"
            )
        return {
            "dataset_name": model["schema"],
            "table_name": model["name"],
            "destination_path_prefix": destination_path_prefix,
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

    latest_only >> reference_models >> export_reference_models


publish_tides_reference = publish_tides_reference()
