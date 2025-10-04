import os
from datetime import datetime

from operators.dbt_bigquery_to_gcs_operator import DBTBigQueryToGCSOperator
from operators.dbt_manifest_to_dictionary_operator import (
    DBTManifestToDictionaryOperator,
)
from operators.dbt_manifest_to_metadata_operator import DBTManifestToMetadataOperator
from operators.gcs_to_ckan_operator import GCSToCKANOperator
from operators.items_to_gcs_operator import ItemsToGCSOperator

from airflow import DAG, XComArg
from airflow.operators.latest_only import LatestOnlyOperator

with DAG(
    dag_id="publish_gtfs",
    tags=["gtfs", "open-data"],
    # Every month
    schedule="0 0 1 * *",
    start_date=datetime(2025, 10, 1),
    catchup=False,
):
    latest_only = LatestOnlyOperator(task_id="latest_only", depends_on_past=False)

    metadata_items = DBTManifestToMetadataOperator(
        task_id="dbt_manifest_to_metadata",
        bucket_name=os.getenv("CALITP_BUCKET__DBT_DOCS"),
        object_name="manifest.json",
    )

    dictionary_items = DBTManifestToDictionaryOperator(
        task_id="dbt_manifest_to_dictionary",
        bucket_name=os.getenv("CALITP_BUCKET__DBT_DOCS"),
        object_name="manifest.json",
    )

    metadata_to_gcs = ItemsToGCSOperator(
        task_id="metadata_to_gcs",
        bucket_name=os.getenv("CALITP_BUCKET__PUBLISH"),
        object_name="california_open_data__metadata/dt={{ ds }}/ts={{ ts }}/metadata.csv",
        items=XComArg(metadata_items),
    )

    dictionary_to_gcs = ItemsToGCSOperator(
        task_id="dictionary_to_gcs",
        bucket_name=os.getenv("CALITP_BUCKET__PUBLISH"),
        object_name="california_open_data__dictionary/dt={{ ds }}/ts={{ ts }}/dictionary.csv",
        items=XComArg(dictionary_items),
    )

    metadata_to_ckan = GCSToCKANOperator(
        task_id="metadata_to_ckan",
        bucket_name=os.getenv("CALITP_BUCKET__PUBLISH"),
        object_name="california_open_data__metadata/dt={{ ds }}/ts={{ ts }}/metadata.csv",
        dataset_id="cal-itp-gtfs-ingest-pipeline-dataset",
        resource_name="Cal-ITP GTFS Schedule Metadata",
    )

    dictionary_to_ckan = GCSToCKANOperator(
        task_id="dictionary_to_ckan",
        bucket_name=os.getenv("CALITP_BUCKET__PUBLISH"),
        object_name="california_open_data__dictionary/dt={{ ds }}/ts={{ ts }}/dictionary.csv",
        dataset_id="cal-itp-gtfs-ingest-pipeline-dataset",
        resource_name="Cal-ITP GTFS Schedule Data Dictionary",
    )

    def create_bigquery_kwargs(metadata_item):
        return {
            "destination_object_name": os.path.join(
                f"california_open_data__{metadata_item['DATASET_NAME']}",
                "dt={{ ds }}",
                "ts={{ ts }}",
                f"{metadata_item['DATASET_NAME']}.csv",
            ),
            "table_name": metadata_item["DATASET_NAME"],
        }

    bigquery_to_gcs = DBTBigQueryToGCSOperator.partial(
        task_id="bigquery_to_gcs",
        source_bucket_name=os.getenv("CALITP_BUCKET__DBT_DOCS"),
        source_object_name="manifest.json",
        destination_bucket_name=os.getenv("CALITP_BUCKET__PUBLISH"),
    ).expand_kwargs(metadata_items.output.map(create_bigquery_kwargs))

    def create_ckan_kwargs(metadata_item):
        return {
            "object_name": os.path.join(
                f"california_open_data__{metadata_item['DATASET_NAME']}",
                "dt={{ ds }}",
                "ts={{ ts }}",
                f"{metadata_item['DATASET_NAME']}.csv",
            ),
            "resource_name": metadata_item["DATASET_NAME"],
        }

    bigquery_to_ckan = GCSToCKANOperator.partial(
        task_id="bigquery_to_ckan",
        bucket_name=os.getenv("CALITP_BUCKET__PUBLISH"),
        dataset_id="cal-itp-gtfs-ingest-pipeline-dataset",
    ).expand_kwargs(metadata_items.output.map(create_ckan_kwargs))

    latest_only >> metadata_items
    latest_only >> dictionary_items
    metadata_to_gcs >> metadata_to_ckan
    dictionary_to_gcs >> dictionary_to_ckan
    bigquery_to_gcs >> bigquery_to_ckan
