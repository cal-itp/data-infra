{{ config(materialized='table') }}

WITH dim_schedule_feeds AS (
    SELECT *
    FROM {{ ref('dim_schedule_feeds') }}
),

int_gtfs_schedule__deduped_fare_transfer_rules AS (
    SELECT *
    FROM {{ ref('int_gtfs_schedule__deduped_fare_transfer_rules') }}
),

make_dim AS (
{{ make_schedule_file_dimension_from_dim_schedule_feeds('dim_schedule_feeds', 'int_gtfs_schedule__deduped_fare_transfer_rules') }}
),

dim_fare_transfer_rules AS (
    SELECT
        {{ dbt_utils.surrogate_key(['feed_key', 'from_leg_group_id', 'to_leg_group_id', 'fare_product_id', 'transfer_count', 'duration_limit']) }} AS key,
        base64_url,
        feed_key,
        gtfs_dataset_key,
        from_leg_group_id,
        to_leg_group_id,
        transfer_count,
        duration_limit,
        duration_limit_type,
        fare_transfer_type,
        fare_product_id,
        _valid_from,
        _valid_to
    FROM make_dim
)

SELECT * FROM dim_fare_transfer_rules
