{{ config(materialized='table') }}

WITH fct_daily_scheduled_trips AS (

    SELECT *
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

stops_by_day_by_route AS (

    SELECT

        trips.service_date,
        trips.activity_date,
        trips.feed_key,
        COALESCE(CAST(trips.route_type AS INT), 1000) AS route_type,

        stop_times.stop_id,

        COUNT(*) AS stop_events_count_by_route,

        LOGICAL_OR(
            trips.contains_warning_duplicate_stop_times_primary_key
        ) AS contains_warning_duplicate_stop_times_primary_key,
        LOGICAL_OR(
            trips.contains_warning_duplicate_trip_primary_key
        ) AS contains_warning_duplicate_trip_primary_key,
        LOGICAL_OR(
            trips.contains_warning_missing_foreign_key_stop_id
        ) AS contains_warning_missing_foreign_key_stop_id

    FROM dim_stop_times AS stop_times
    LEFT JOIN fct_daily_scheduled_trips AS trips
        ON trips.feed_key = stop_times.feed_key
            AND trips.trip_id = stop_times.trip_id
    GROUP BY service_date, activity_date, feed_key, route_type, stop_id

),

stops_by_day AS (

    SELECT

        service_date,
        activity_date,
        feed_key,
        stop_id,

        SUM(stop_events_count_by_route) AS stop_event_count,

        LOGICAL_OR(
            contains_warning_duplicate_stop_times_primary_key
        ) AS contains_warning_duplicate_stop_times_primary_key,
        LOGICAL_OR(
            contains_warning_duplicate_trip_primary_key
        ) AS contains_warning_duplicate_trip_primary_key,
        LOGICAL_OR(
            contains_warning_missing_foreign_key_stop_id
        ) AS contains_warning_missing_foreign_key_stop_id

    FROM stops_by_day_by_route
    GROUP BY service_date, activity_date, feed_key, stop_id
),

pivot_to_route_type AS (

    SELECT *
    FROM
        (SELECT

            service_date,
            activity_date,
            feed_key,
            route_type,
            stop_id,
            stop_events_count_by_route

        FROM stops_by_day_by_route)
    PIVOT(
        SUM(stop_events_count_by_route) AS route_type
        FOR route_type IN
        (0, 1, 2, 3, 4, 5, 6, 7, 11, 12, 1000)
    )
),

fct_daily_scheduled_stops AS (
    SELECT

        {{ dbt_utils.surrogate_key(['pivoted.service_date', 'stops.key']) }} AS key,

        pivoted.service_date,
        pivoted.activity_date,
        pivoted.feed_key,
        pivoted.stop_id,

        stops_by_day.stop_event_count,

        pivoted.route_type_0,
        pivoted.route_type_1,
        pivoted.route_type_2,
        pivoted.route_type_3,
        pivoted.route_type_4,
        pivoted.route_type_5,
        pivoted.route_type_6,
        pivoted.route_type_7,
        pivoted.route_type_11,
        pivoted.route_type_12,
        pivoted.route_type_1000 AS missing_route_type,

        stops_by_day.contains_warning_duplicate_stop_times_primary_key,
        stops_by_day.contains_warning_duplicate_trip_primary_key,

        stops.warning_duplicate_primary_key AS contains_warning_duplicate_stop_primary_key,

        stops.key AS stop_key,
        stops.tts_stop_name,
        stops.pt_geom,
        stops.parent_station,
        stops.stop_code,
        stops.stop_name,
        stops.stop_desc,
        stops.location_type,
        stops.stop_timezone,
        stops.wheelchair_boarding

    FROM dim_stops AS stops
    INNER JOIN pivot_to_route_type AS pivoted
        ON pivoted.stop_id = stops.stop_id
        AND pivoted.feed_key = stops.feed_key
    LEFT JOIN stops_by_day
        ON pivoted.stop_id = stops_by_day.stop_id
        AND pivoted.service_date = stops_by_day.service_date
        AND pivoted.feed_key = stops_by_day.feed_key
)

SELECT * FROM fct_daily_scheduled_stops
