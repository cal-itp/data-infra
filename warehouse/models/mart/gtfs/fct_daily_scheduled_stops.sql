{{ config(materialized='table') }}

WITH fct_daily_scheduled_trips AS (

    SELECT

        service_date,
        feed_key,
        service_id,
        trip_id,
        route_id,
        route_type

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
        CAST(trips.route_type AS INT) AS route_type,

        stop_times.stop_id,

        COUNT(*) AS stop_event_count

    FROM dim_stop_times AS stop_times
    LEFT JOIN fct_daily_scheduled_trips AS trips
        ON trips.feed_key = stop_times.feed_key
            AND trips.trip_id = stop_times.trip_id
    GROUP BY service_date, feed_key, route_type, stop_id
),

pivot_to_route_type AS (

    SELECT *
    FROM
        (SELECT

            service_date,
            feed_key,
            route_type,
            stop_id,
            stop_event_count

        FROM stops_by_day)
    PIVOT(
        SUM(stop_event_count) AS route_type
        FOR route_type IN
        (0, 1, 2, 3, 4, 5, 11)
    )
),

fct_daily_scheduled_stops AS (
    SELECT

        pivot.service_date,
        pivot.feed_key,
        pivot.stop_id,

        stops_by_day.stop_event_count,

        IFNULL(pivot.route_type_0, 0) AS route_type_0_count,
        IFNULL(pivot.route_type_1, 0) AS route_type_1_count,
        IFNULL(pivot.route_type_2, 0) AS route_type_2_count,
        IFNULL(pivot.route_type_3, 0) AS route_type_3_count,
        IFNULL(pivot.route_type_4, 0) AS route_type_4_count,
        IFNULL(pivot.route_type_5, 0) AS route_type_5_count,
        IFNULL(pivot.route_type_11, 0) AS route_type_11_count,

        stops.tts_stop_name,
        stops.pt_geom,
        stops.parent_station,
        stops.stop_code,
        stops.stop_name,
        stops.stop_desc,
        stops.location_type,
        stops.stop_timezone,
        stops.wheelchair_boarding

    FROM pivot_to_route_type AS pivot
    LEFT JOIN dim_stops AS stops
        ON pivot.stop_id = stops.stop_id
    LEFT JOIN stops_by_day
        ON pivot.stop_id = stops_by_day.stop_id
        AND pivot.service_date = stops_by_day.service_date
        AND pivot.feed_key = stops_by_day.feed_key
)

SELECT * FROM fct_daily_scheduled_stops
