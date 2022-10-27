{{ config(materialized='table') }}

WITH dim_schedule_feeds AS (
    SELECT *
    FROM {{ ref('dim_schedule_feeds') }}
),

int_gtfs_schedule__incremental_trips AS (
    SELECT *
    FROM {{ ref('int_gtfs_schedule__incremental_trips') }}
),

make_dim AS (
{{ make_schedule_file_dimension_from_dim_schedule_feeds('dim_schedule_feeds', 'int_gtfs_schedule__incremental_trips') }}
),

bad_rows AS (
    SELECT
        base64_url,
        ts,
        trip_id,
        TRUE AS warning_duplicate_primary_key
    FROM make_dim
    GROUP BY base64_url, ts, trip_id
    HAVING COUNT(*) > 1
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
        COALESCE(warning_duplicate_primary_key, FALSE) AS warning_duplicate_primary_key,
        _valid_from,
        _valid_to
    FROM make_dim
    LEFT JOIN bad_rows
        USING (base64_url, ts, trip_id)
)

SELECT * FROM dim_trips
