{{ config(materialized='table') }}

WITH dim_schedule_feeds AS (
    SELECT *
    FROM {{ ref('dim_schedule_feeds') }}
),

stg_gtfs_schedule__fare_rules AS (
    SELECT *
    FROM {{ ref('stg_gtfs_schedule__fare_rules') }}
),

make_dim AS (
{{ make_schedule_file_dimension_from_dim_schedule_feeds('dim_schedule_feeds', 'stg_gtfs_schedule__fare_rules') }}
),

dim_fare_rules AS (
    SELECT
        {{ dbt_utils.surrogate_key(['feed_key', 'fare_id', 'route_id', 'origin_id', 'destination_id', 'contains_id']) }} AS key,
        feed_key,
        gtfs_dataset_key,
        fare_id,
        route_id,
        origin_id,
        destination_id,
        contains_id,
        base64_url,
        _valid_from,
        _valid_to
    FROM make_dim
)

SELECT * FROM dim_fare_rules
