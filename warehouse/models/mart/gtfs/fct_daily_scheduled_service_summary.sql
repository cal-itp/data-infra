{{ config(materialized='table') }}

WITH fct_daily_scheduled_trips AS (

    SELECT *
    FROM {{ ref('fct_daily_scheduled_trips') }}

),

fct_daily_scheduled_service_summary AS (

    SELECT

        service_date,
        feed_key,
        SUM(service_hours) AS ttl_service_hours,
        COUNT(DISTINCT trip_id) AS n_trips,
        MIN(trip_first_departure_ts) AS first_departure_ts,
        MAX(trip_last_arrival_ts) AS last_arrival_ts,
        SUM(n_stop_times) AS n_stop_times,
        COUNT(DISTINCT route_id) AS n_routes,
        LOGICAL_OR(contains_warning_duplicate_stop_times_primary_key) AS contains_warning_duplicate_stop_times_primary_key,
        LOGICAL_OR(contains_warning_duplicate_trip_primary_key) AS contains_warning_duplicate_trip_primary_key,

        -- @Laurie, if none of the calculations in this table rely on stop_id, do we need to keep the warning column below?
        LOGICAL_OR(contains_warning_missing_foreign_key_stop_id) AS contains_warning_missing_foreign_key_stop_id

    FROM fct_daily_scheduled_trips
    GROUP BY service_date, feed_key
)

SELECT * FROM fct_daily_scheduled_service_summary
