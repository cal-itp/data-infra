{{ config(materialized='table') }}

WITH latest_gtfs_datasets AS (
    {{ get_latest_dense_rank(
        external_table = ref('stg_transit_database__gtfs_datasets'),
        order_by = 'calitp_extracted_at DESC'
        ) }}
),

dim_gtfs_datasets AS (
    SELECT
        airtable_record_id as key,
        airtable_record_id,
        name,
        data,
        uri,
        future_uri,
        aggregated_to_gtfs_dataset_airtable_record_id,
        deprecated_date,
        data_quality_pipeline,
        schedule_to_use_for_rt_validation_gtfs_dataset_airtable_record_id,
        -- TODO: make this table actually historical
        CAST("1901-01-01" AS TIMESTAMP) AS _valid_from,
        {{ make_end_of_valid_range('CAST("2099-01-01" AS TIMESTAMP))' }} AS _valid_to
    FROM latest_gtfs_datasets
)

SELECT * FROM dim_gtfs_datasets
