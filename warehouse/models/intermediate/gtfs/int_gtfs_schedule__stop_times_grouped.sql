{{ config(materialized='table') }}

WITH

dim_stop_times AS (
    SELECT * FROM {{ ref('dim_stop_times') }}
),

int_gtfs_schedule__frequencies_stop_times AS (
    SELECT * FROM {{ ref('int_gtfs_schedule__frequencies_stop_times') }}
    WHERE stop_id IS NOT NULL
),

stops AS (
    SELECT
        feed_key,
        stop_id,
        stop_timezone_coalesced,
        COUNT(*) AS ct
    FROM {{ ref('dim_stops') }}
    WHERE stop_id IS NOT NULL
    GROUP BY 1, 2, 3
    -- we can have duplicate stop IDs within a given feed (this is not valid, but happens)
    -- just keep the most common time zone (very unlikely to have same stop ID but different time zone)
    QUALIFY RANK() OVER (PARTITION BY feed_key, stop_id ORDER BY ct DESC) = 1
),

stops_times_with_tz AS (
    SELECT
        dim_stop_times.* EXCEPT(departure_sec, arrival_sec),
        COALESCE(freq.trip_stop_arrival_time_sec, arrival_sec) AS trip_stop_arrival_sec,
        freq.trip_start_time_sec,
        dim_stop_times.departure_sec AS trip_stop_departure_sec,
        freq.iteration_num,
        freq.exact_times,
        freq.trip_id IS NOT NULL AS frequencies_defined_trip,
        COALESCE(FIRST_VALUE(stop_timezone_coalesced)
            OVER (PARTITION BY feed_key, trip_id
                ORDER BY dim_stop_times.stop_sequence
                ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING), feed_timezone) AS trip_start_timezone,
        COALESCE(LAST_VALUE(stop_timezone_coalesced)
            OVER (PARTITION BY feed_key, trip_id
                ORDER BY dim_stop_times.stop_sequence
                ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING), feed_timezone) AS trip_end_timezone
    FROM dim_stop_times
    LEFT JOIN stops
        USING (feed_key, stop_id)
    LEFT JOIN int_gtfs_schedule__frequencies_stop_times freq
        USING (feed_key, trip_id, stop_id)
),

int_gtfs_schedule__stop_times_grouped AS (
    SELECT
        trip_id,
        feed_key,
        base64_url,
        feed_timezone,
        trip_start_timezone,
        trip_end_timezone,
        iteration_num,
        exact_times,
        COUNT(DISTINCT stop_id) AS n_stops,
        COUNT(*) AS n_stop_times,
        -- note: not using the interval columns here because the interval type doesn't support aggregation
        -- so we'd probably have to lean on seconds/window functions anyway
        -- for frequency based trips, we have trip_start_time_sec, else just use departure sec
        COALESCE(MIN(trip_start_time_sec), MIN(trip_stop_departure_sec)) AS trip_first_departure_sec,
        MAX(trip_stop_arrival_sec) AS trip_last_arrival_sec,
        (MAX(trip_stop_arrival_sec) - COALESCE(MIN(trip_start_time_sec), MIN(trip_stop_departure_sec))) / 3600 AS service_hours,
        LOGICAL_OR(
            warning_duplicate_primary_key
        ) AS contains_warning_duplicate_primary_key,
        LOGICAL_OR(
            warning_missing_foreign_key_stop_id
        ) AS contains_warning_missing_foreign_key_stop_id,
        LOGICAL_OR(
            frequencies_defined_trip
        ) AS frequencies_defined_trip

    FROM stops_times_with_tz
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
)

SELECT * FROM int_gtfs_schedule__stop_times_grouped
