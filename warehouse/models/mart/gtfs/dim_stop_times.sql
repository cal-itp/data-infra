{{ config(materialized='table') }}

WITH dim_schedule_feeds AS (
    SELECT *
    FROM {{ ref('dim_schedule_feeds') }}
),

stg_gtfs_schedule__stop_times AS (
    SELECT *
    FROM {{ ref('stg_gtfs_schedule__stop_times') }}
),

make_dim AS (
{{ make_schedule_file_dimension_from_dim_schedule_feeds('dim_schedule_feeds', 'stg_gtfs_schedule__stop_times') }}
),

dim_stop_times AS (
    SELECT
        {{ dbt_utils.surrogate_key(['feed_key', 'trip_id', 'stop_sequence']) }} AS key,
        base64_url,
        feed_key,
        trip_id,
        stop_id,
        stop_sequence,
        arrival_time,
        departure_time,
        stop_headsign,
        pickup_type,
        drop_off_type,
        continuous_pickup,
        continuous_drop_off,
        shape_dist_traveled,
        timepoint,
        _valid_from,
        _valid_to
    FROM make_dim
)

SELECT * FROM dim_stop_times
