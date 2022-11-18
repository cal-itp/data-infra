{{ config(materialized='table') }}

WITH

dim_stop_times AS (

    SELECT * FROM {{ ref('dim_stop_times') }}

),

trip_calculations AS (

    SELECT

        trip_id,
        feed_key,
        COUNT(DISTINCT stop_id) AS n_stops,
        COUNT(*) AS n_stop_times,
        COUNT(DISTINCT trip_id) AS n_trips,
        MIN(departure_sec) AS trip_first_departure_ts,
        MAX(arrival_sec) AS trip_last_arrival_ts,
        (MAX(arrival_sec) - MIN(departure_sec)) / 3600 AS service_hours
        --, COUNT(DISTINCT route_id) AS n_routes


    FROM dim_stop_times
    GROUP BY trip_id, feed_key

)

SELECT * FROM trip_calculations
