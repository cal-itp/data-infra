{{ config(materialized='table') }}

WITH

dim_stop_times AS (
    SELECT * FROM {{ ref('dim_stop_times') }}
),

dim_stops AS (
    SELECT
        feed_key,
        stop_id,
        COALESCE(stop_timezone, feed_timezone) AS stop_timezone
    FROM {{ ref('dim_stops') }}
),

stops_times_with_tz AS (
    SELECT
        feed_key,
        trip_id,
        stop_id,
        stop_timezone,
    FROM dim_stop_times
    LEFT JOIN dim_stops
        USING (feed_key, stop_id)
),

-- get the most common time zone for each trip
-- this is imperfect for ex. Amtrak but
-- todo: remove noqa once cte is used
trip_timezone AS ( -- noqa: ST03
    SELECT
        feed_key,
        trip_id,
        stop_timezone AS trip_timezone,
        COUNT(*) AS trip_stop_tz_count
    FROM stops_times_with_tz
    GROUP BY 1, 2, 3
    QUALIFY RANK() OVER (PARTITION BY feed_key, trip_id ORDER BY trip_stop_tz_count DESC, stop_timezone ASC) = 1
),

int_gtfs_schedule__stop_times_grouped AS (
    SELECT
        trip_id,
        feed_key,
        COUNT(DISTINCT stop_id) AS n_stops,
        COUNT(*) AS n_stop_times,
        -- note: not using the interval columns here because the interval type doesn't support aggregation so we'd probably have to lean on seconds/window functions anyway
        MIN(departure_sec) AS trip_first_departure_sec,
        MAX(arrival_sec) AS trip_last_arrival_sec,
        (MAX(arrival_sec) - MIN(departure_sec)) / 3600 AS service_hours,
        LOGICAL_OR(
            warning_duplicate_primary_key
        ) AS contains_warning_duplicate_primary_key,
        LOGICAL_OR(
            warning_missing_foreign_key_stop_id
        ) AS contains_warning_missing_foreign_key_stop_id

    FROM dim_stop_times
    GROUP BY 1, 2
)

SELECT * FROM int_gtfs_schedule__stop_times_grouped
