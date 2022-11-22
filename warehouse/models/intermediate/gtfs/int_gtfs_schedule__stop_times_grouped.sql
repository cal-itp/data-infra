{{ config(materialized='table') }}

WITH

dim_stop_times AS (

    SELECT * FROM {{ ref('dim_stop_times') }}

),

int_gtfs_schedule__stop_times_grouped AS (

    SELECT

        trip_id,
        feed_key,
        COUNT(DISTINCT stop_id) AS n_stops,
        COUNT(*) AS n_stop_times,
        MIN(departure_sec) AS trip_first_departure_ts,
        MAX(arrival_sec) AS trip_last_arrival_ts,
        (MAX(arrival_sec) - MIN(departure_sec)) / 3600 AS service_hours,
        LOGICAL_OR(warning_duplicate_primary_key) AS contains_warning_duplicate_primary_key,
        LOGICAL_OR(warning_missing_foreign_key_stop_id) AS contains_warning_missing_foreign_key_stop_id

    FROM dim_stop_times
    GROUP BY trip_id, feed_key

)

SELECT * FROM int_gtfs_schedule__stop_times_grouped
