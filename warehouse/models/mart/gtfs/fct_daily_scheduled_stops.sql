{{
    config(
        materialized='incremental',
        unique_key = 'key',
        cluster_by='feed_key',
    )
}}

WITH fct_scheduled_trips AS (

    SELECT *
    FROM {{ ref('fct_scheduled_trips') }}
    WHERE {{ incremental_where(default_start_var='GTFS_SCHEDULE_START',
                               this_dt_column='service_date',
                               filter_dt_column='service_date',
                               dev_lookback_days = 60) }}
),

dim_stop_times AS (
    SELECT *
    FROM {{ ref('dim_stop_times') }}
    WHERE DATE(_feed_valid_from) > "2025-06-01"
),

dim_stops AS (
    SELECT *
    FROM {{ ref('dim_stops') }}
    WHERE DATE(_feed_valid_from) > "2025-06-01"

),

dim_routes AS (
    SELECT *
    FROM {{ ref('dim_routes') }}
    WHERE DATE(_feed_valid_from) > "2025-06-01"

),

int_gtfs_schedule__frequencies_stop_times AS (
    SELECT *
    FROM {{ ref('int_gtfs_schedule__frequencies_stop_times') }}
),

stops_by_day_by_route AS (

    SELECT
        trips.service_date,
        trips.feed_key,
        COALESCE(CAST(trips.route_type AS INT), 1000) AS route_type,
        stop_times.stop_id,
        stop_times._feed_valid_from,
        trips.feed_timezone,

        COUNT(*) AS stop_events_count_by_route,

        MIN(DATETIME(TIMESTAMP_ADD(
            {{ gtfs_noon_minus_twelve_hours('trips.service_date', 'trips.feed_timezone') }},
            INTERVAL COALESCE(freq.trip_stop_arrival_time_sec, stop_times.arrival_sec) SECOND
            ), "America/Los_Angeles")) AS first_stop_arrival_datetime_pacific,

        MAX(DATETIME(TIMESTAMP_ADD(
            {{ gtfs_noon_minus_twelve_hours('trips.service_date', 'trips.feed_timezone') }},
            INTERVAL COALESCE(freq.trip_stop_departure_time_sec, stop_times.departure_sec) SECOND
            ), "America/Los_Angeles")) AS last_stop_departure_datetime_pacific,

        LOGICAL_OR(
            trips.contains_warning_duplicate_stop_times_primary_key
        ) AS contains_warning_duplicate_stop_times_primary_key,
        LOGICAL_OR(
            trips.contains_warning_duplicate_trip_primary_key
        ) AS contains_warning_duplicate_trip_primary_key,
        LOGICAL_OR(
            trips.contains_warning_missing_foreign_key_stop_id
        ) AS contains_warning_missing_foreign_key_stop_id,

    FROM fct_scheduled_trips AS trips
    LEFT JOIN dim_stop_times AS stop_times
        ON trips.feed_key = stop_times.feed_key
            AND trips.trip_id = stop_times.trip_id
    LEFT JOIN int_gtfs_schedule__frequencies_stop_times freq
        ON stop_times.feed_key = freq.feed_key
        AND stop_times.trip_id = freq.trip_id
        AND stop_times.stop_id = freq.stop_id
    GROUP BY 1, 2, 3, 4, 5, 6

),

stops_by_day_by_route2 AS (
    SELECT
        *,
        CASE
            WHEN route_type IN (0, 1, 2) THEN "rail"
            WHEN route_type = 3 THEN "bus"
            WHEN route_type = 4 THEN "ferry"
            WHEN route_type = 11 THEN "trolleybus"
            WHEN route_type IN (5, 6, 7, 12) THEN "other_rail"
            WHEN route_type = 1000 THEN "missing"
        END AS transit_mode,
    FROM stops_by_day_by_route
),

stops_by_day AS (

    SELECT

        service_date,
        feed_timezone,
        feed_key,
        stop_id,
        MAX(_feed_valid_from) as _feed_valid_from,

        SUM(stop_events_count_by_route) AS stop_event_count,

        MIN(first_stop_arrival_datetime_pacific) AS first_stop_arrival_datetime_pacific,
        MAX(last_stop_departure_datetime_pacific) AS last_stop_departure_datetime_pacific,

        LOGICAL_OR(
            contains_warning_duplicate_stop_times_primary_key
        ) AS contains_warning_duplicate_stop_times_primary_key,
        LOGICAL_OR(
            contains_warning_duplicate_trip_primary_key
        ) AS contains_warning_duplicate_trip_primary_key,
        LOGICAL_OR(
            contains_warning_missing_foreign_key_stop_id
        ) AS contains_warning_missing_foreign_key_stop_id,

        ARRAY_AGG(DISTINCT route_type) as route_type_array,
        ARRAY_AGG(DISTINCT transit_mode) AS transit_mode_array

    FROM stops_by_day_by_route2
    GROUP BY 1, 2, 3, 4
),

pivot_to_route_type AS (

    SELECT *
    FROM
        (SELECT

            service_date,
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

        {{ dbt_utils.generate_surrogate_key(['pivoted.service_date', 'stops.key']) }} AS key,

        pivoted.service_date,
        pivoted.feed_key,
        pivoted.stop_id,

        stops_by_day.feed_timezone,
        stops_by_day.stop_event_count,
        stops_by_day.first_stop_arrival_datetime_pacific,
        stops_by_day.last_stop_departure_datetime_pacific,
        stops_by_day._feed_valid_from,

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
        stops_by_day.route_type_array,
        stops_by_day.transit_mode_array,
        ARRAY_LENGTH(stops_by_day.transit_mode_array) AS n_transit_modes,

        stops.warning_duplicate_gtfs_key AS contains_warning_duplicate_stop_primary_key,

        stops.key AS stop_key,
        stops.tts_stop_name,
        stops.pt_geom,
        stops.parent_station,
        stops.stop_code,
        stops.stop_name,
        stops.stop_desc,
        stops.location_type,
        stops.stop_timezone_coalesced,
        stops.wheelchair_boarding,


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
