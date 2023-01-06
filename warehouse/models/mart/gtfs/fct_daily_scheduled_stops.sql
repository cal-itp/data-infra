{{ config(materialized='table') }}

WITH fct_daily_scheduled_trips AS (

    SELECT

        service_date,
        feed_key,
        service_id,
        trip_id,
        route_id

    FROM {{ ref('fct_daily_scheduled_trips') }}
),

dim_stop_times AS (
    SELECT *
    FROM {{ ref('dim_stop_times') }}
),

dim_stops AS (
    SELECT *
    FROM {{ ref('dim_stops') }}
),

dim_routes AS (
    SELECT *
    FROM {{ ref('dim_routes') }}
),


stops_by_day AS (

    SELECT

        trips.service_date,
        trips.feed_key,
        trips.route_type,

        stop_times.stop_id,

        count(*) AS stop_event_count,

    FROM dim_stop_times AS stop_times
    LEFT JOIN fct_daily_scheduled_trips AS trips
        ON trips.feed_key = stop_times.feed_key
            AND trips.trip_id = stop_times.trip_id
    -- WHERE service_date = '2023-01-02'
    GROUP BY service_date, feed_key, route_type, stop_id
),

fct_daily_scheduled_stops AS (
    SELECT

        stops_by_day.service_date,
        stops_by_day.feed_key,
        stops_by_day.route_type,
        stops_by_day.stop_id,
        stops_by_day.stop_event_count,

        stops.tts_stop_name,
        stops.pt_geom,
        stops.parent_station,
        stops.stop_code,
        stops.stop_name,
        stops.stop_desc,
        stops.location_type,
        stops.stop_timezone,
        stops.wheelchair_boarding

    FROM stops_by_day
    LEFT JOIN dim_stops AS stops
        ON stops_by_day.stop_id = stops.stop_id
    -- WHERE service_date = '2023-01-02'
)

SELECT * FROM fct_daily_scheduled_stops
