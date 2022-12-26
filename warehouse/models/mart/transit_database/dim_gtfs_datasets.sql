{{ config(materialized='table') }}

WITH latest_gtfs_datasets AS (
    {{ get_latest_dense_rank(
        external_table = ref('stg_transit_database__gtfs_datasets'),
        order_by = 'calitp_extracted_at DESC'
        ) }}
),

dim_gtfs_datasets AS (
    SELECT
        key,
        name,
        type,
        regional_feed_type,
        uri,
        future_uri,
        aggregated_to_gtfs_dataset_key,
        deprecated_date,
        data_quality_pipeline,
        schedule_to_use_for_rt_validation_gtfs_dataset_key,
        base64_url,
        calitp_extracted_at
    FROM latest_gtfs_datasets
)

SELECT * FROM dim_gtfs_datasets
