import os
from datetime import datetime

from operators.dbt_big_query_to_gcs_operator import DBTBigQueryToGCSOperator
from operators.dbt_manifest_to_metadata_operator import DBTManifestToMetadataOperator
from operators.gcs_to_ckan_operator import GCSToCKANOperator
from operators.items_to_gcs_operator import ItemsToGCSOperator

from airflow import DAG, XComArg

with DAG(
    dag_id="publish_open_data",
    tags=["gtfs", "open-data"],
    # Every month
    schedule="0 0 0 * *",
    start_date=datetime(2025, 10, 1),
    catchup=True,
):
    metadata_items = DBTManifestToMetadataOperator(
        task_id="dbt_manifest_to_metadata",
        bucket_name=os.getenv("CALITP_BUCKET__DBT_DOCS"),
        object_name="manifest.json",
    )

    # dictionary_items = DBTManifestToDictionaryOperator(
    #     task_id="dbt_manifest_to_dictionary",
    #     bucket_name=os.getenv("CALITP_BUCKET__DBT_DOCS"),
    #     object_name="manifest.json",
    # )

    ItemsToGCSOperator(
        task_id="metadata_to_gcs",
        bucket_name=os.getenv("CALITP_BUCKET__PUBLISH"),
        object_name="california_open_data__metadata/dt={{ ds }}/ts={{ ts }}/metadata.csv",
        items=metadata_items,
    )

    # ItemsToGCSOperator(
    #     task_id="dictionary_to_gcs",
    #     bucket_name=os.getenv("CALITP_BUCKET__PUBLISH"),
    #     object_name="california_open_data__dictionary/dt={{ ds }}/ts={{ ts }}/dictionary.csv",
    #     items=dictionary_items,
    # )

    bigquery_tables = DBTBigQueryToGCSOperator.partial(
        task_id="bigquery_to_gcs",
        source_bucket_name=os.getenv("CALITP_BUCKET__DBT_DOCS"),
        source_object_name="manifest.json",
        destination_bucket_name=os.getenv("CALITP_BUCKET__PUBLISH"),
        destination_object_name="california_open_data__{{ task.parameters['DATASET_NAME'] }}/dt={{ ds }}/ts={{ ts }}/{{ task.parameters['DATASET_NAME'] }}.csv",
        table_name="{{ task.parameters['DATASET_NAME'] }}",
    ).expand(parameters=XComArg(metadata_items))

    GCSToCKANOperator(
        task_id="metadata_to_ckan",
        bucket_name=os.getenv("CALITP_BUCKET__PUBLISH"),
        object_name="california_open_data__metadata/dt={{ ds }}/ts={{ ts }}/metadata.csv",
        dataset_id="cal-itp-gtfs-ingest-pipeline-dataset",
        resource_name="Cal-ITP GTFS Schedule Metadata",
    )

    # GCSToCKANOperator(
    #     task_id="dictionary_to_ckan",
    #     bucket_name=os.getenv("CALITP_BUCKET__PUBLISH"),
    #     object_name="california_open_data__dictionary/dt={{ ds }}/ts={{ ts }}/dictionary.csv",
    #     dataset_id="cal-itp-gtfs-ingest-pipeline-dataset",
    #     resource_name="Cal-ITP GTFS Schedule Data Dictionary",
    # )

    GCSToCKANOperator.partial(
        task_id="table_to_ckan",
        bucket_name=os.getenv("CALITP_BUCKET__PUBLISH"),
        object_name="california_open_data__{{ task.parameters['DATASET_NAME'] }}/dt={{ ds }}/ts={{ ts }}/{{ task.parameters['DATASET_NAME'] }}.csv",
        dataset_id="cal-itp-gtfs-ingest-pipeline-dataset",
        resource_name="{{ task.parameters['DATASET_NAME'] }}",
    ).expand(parameters=XComArg(metadata_items))
