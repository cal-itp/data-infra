{{ config(materialized='table') }}

WITH dim_schedule_feeds AS (
    SELECT *
    FROM {{ ref('dim_schedule_feeds') }}
),

stg_gtfs_schedule__trips AS (
    SELECT *
    FROM {{ ref('stg_gtfs_schedule__trips') }}
),

make_dim AS (
{{ make_schedule_file_dimension_from_dim_schedule_feeds('dim_schedule_feeds', 'stg_gtfs_schedule__trips') }}
),

dim_trips AS (
    SELECT
        {{ dbt_utils.surrogate_key(['feed_key', 'trip_id']) }} AS key,
        base64_url,
        feed_key,
        route_id,
        service_id,
        trip_id,
        shape_id,
        trip_headsign,
        trip_short_name,
        direction_id,
        block_id,
        wheelchair_accessible,
        bikes_allowed,
        _valid_from,
        _valid_to
    FROM make_dim
)

SELECT * FROM dim_trips
