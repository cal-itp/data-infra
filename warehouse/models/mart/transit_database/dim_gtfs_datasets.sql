{{ config(materialized='table') }}

WITH dim AS (
    SELECT *
    FROM {{ ref('int_transit_database__gtfs_datasets_dim') }}
),

dim_gtfs_datasets AS (
    SELECT
        key,
        original_record_id,
        name,
        type,
        regional_feed_type,
        uri,
        future_uri,
        deprecated_date,
        data_quality_pipeline,
        datasets.key AS schedule_to_use_for_rt_validation_gtfs_dataset_key,
        base64_url,
        _is_current,
        _valid_from,
        _valid_to
    FROM dim
)

SELECT * FROM dim_gtfs_datasets
