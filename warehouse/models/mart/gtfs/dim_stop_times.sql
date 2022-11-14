{{ config(materialized='table') }}

WITH dim_schedule_feeds AS (
    SELECT *
    FROM {{ ref('dim_schedule_feeds') }}
),

int_gtfs_schedule__incremental_stop_times AS (
    SELECT *
    FROM {{ ref('int_gtfs_schedule__incremental_stop_times') }}
),

make_dim AS (
{{ make_schedule_file_dimension_from_dim_schedule_feeds('dim_schedule_feeds', 'int_gtfs_schedule__incremental_stop_times') }}
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
        COUNT(*) OVER (PARTITION BY base64_url, ts, trip_id, stop_sequence) > 1 AS warning_duplicate_primary_key,
        stop_id IS NULL AS warning_missing_foreign_key_stop_id,
        _valid_from,
        _valid_to
    FROM make_dim
)

SELECT * FROM dim_stop_times
