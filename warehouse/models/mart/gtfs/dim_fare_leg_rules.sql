{{ config(materialized='table') }}

WITH dim_schedule_feeds AS (
    SELECT *
    FROM {{ ref('dim_schedule_feeds') }}
),

int_gtfs_schedule__deduped_fare_leg_rules AS (
    SELECT *
    FROM {{ ref('int_gtfs_schedule__deduped_fare_leg_rules') }}
),

make_dim AS (
{{ make_schedule_file_dimension_from_dim_schedule_feeds('dim_schedule_feeds', 'int_gtfs_schedule__deduped_fare_leg_rules') }}
),

dim_fare_leg_rules AS (
    SELECT
        {{ dbt_utils.surrogate_key(['feed_key', 'network_id', 'from_area_id', 'to_area_id', 'fare_product_id']) }} AS key,
        base64_url,
        feed_key,

        leg_group_id,
        network_id,
        from_area_id,
        to_area_id,
        fare_product_id,
        _valid_from,
        _valid_to
    FROM make_dim
)

SELECT * FROM dim_fare_leg_rules
