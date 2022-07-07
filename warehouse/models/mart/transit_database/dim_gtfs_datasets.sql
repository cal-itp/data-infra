{{ config(materialized='table') }}

WITH stg_transit_database__gtfs_datasets AS (
    SELECT * FROM {{ ref('stg_transit_database__gtfs_datasets') }}
),

dim_gtfs_datasets AS (
    SELECT
        key,
        name,
        data,
        uri,
        future_uri,
        aggregated_to_gtfs_dataset_key,
        deprecated_date,
        data_quality_pipeline,
        schedule_to_use_for_rt_validation_gtfs_dataset_key,
        calitp_extracted_at
    FROM stg_transit_database__gtfs_datasets
)

SELECT * FROM dim_gtfs_datasets
