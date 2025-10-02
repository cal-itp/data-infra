import os
from datetime import datetime

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
        bucket_name=os.getenv("CALITP_BUCKET__PUBLISH"),
        object_name="california_open_data__{{ task.metadata_item[1]['DATASET_NAME'] }}/dt={{ ds }}/ts={{ ts }}/{{ task.metadata_item['DATASET_NAME'] }}.csv",
        table_name="",
    ).expand(metadata_item=XComArg(metadata_items))

    GCSToCKANOperator(
        task_id="metadata_to_ckan",
        bucket_name=os.getenv("CALITP_BUCKET__PUBLISH"),
        object_name="california_open_data__metadata/dt={{ ds }}/ts={{ ts }}/metadata.csv",
        resource_id=os.getenv("CALIFORNIA_OPEN_DATA__METADATA_RESOURCE_ID", "53c05c25-e467-407a-bb29-303875215adc"),
    )

    # GCSToCKANOperator(
    #     task_id="dictionary_to_ckan",
    #     bucket_name=os.getenv("CALITP_BUCKET__PUBLISH"),
    #     object_name="california_open_data__dictionary/dt={{ ds }}/ts={{ ts }}/dictionary.csv",
    #     resource_id=os.getenv("CALIFORNIA_OPEN_DATA__DICTIONARY_RESOURCE_ID", "e26bf6ee-419d-4a95-8e4c-e2b13d5de793"),
    # )

    GCSToCKANOperator.partial(
        task_id="table_to_ckan",
        bucket_name=os.getenv("CALITP_BUCKET__PUBLISH"),
        object_name="california_open_data__{{ task.metadata_item[1]['DATASET_NAME'] }}/dt={{ ds }}/ts={{ ts }}/{{ task.metadata_item['DATASET_NAME'] }}.csv",
        resource_id="{{ task.metadata_item[0] }}",
    ).expand(metadata_item=XComArg(metadata_items))
