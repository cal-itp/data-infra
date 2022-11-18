{{ config(materialized='table') }}

WITH fct_daily_scheduled_trips AS (

    SELECT *
    FROM {{ ref('fct_daily_scheduled_trips') }}

),

fct_daily_reports_service AS (

    SELECT

        service_date,
        feed_key,
        SUM(service_hours) AS ttl_service_hours,
        SUM(n_trips) AS n_trips,
        MIN(trip_first_departure_ts) AS first_departure_ts,
        MAX(trip_last_arrival_ts) AS last_arrival_ts,
        SUM(n_stops) AS n_stops
        --, SUM(n_routes) AS n_routes

    FROM fct_daily_scheduled_trips
    GROUP BY service_date, feed_key
)

SELECT * FROM fct_daily_reports_service
