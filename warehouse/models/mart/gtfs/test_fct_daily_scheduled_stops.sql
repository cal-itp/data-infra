{{
    config(
        materialized='table'
    )
}}

WITH fct_scheduled_trips AS (
    SELECT *
    FROM `cal-itp-data-infra-staging.tiffany_mart_gtfs.fct_scheduled_trips_testing`
    WHERE feed_key = "0cee6f373c3570abb470e27dbe048b54"
),

dim_stops AS (
    SELECT *
    FROM `cal-itp-data-infra-staging.tiffany_mart_gtfs.dim_stops_testing`
    WHERE feed_key = "0cee6f373c3570abb470e27dbe048b54"
),

dim_stop_arrivals AS (
    SELECT *
    FROM `cal-itp-data-infra-staging.tiffany_mart_gtfs.dim_stop_arrivals`
),

stop_times_grouped AS (
    SELECT
        feed_key,
        trip_id,
        stop_id_array,

    FROM `cal-itp-data-infra-staging.tiffany_staging.int_gtfs_schedule__stop_times_grouped_testing`
    WHERE feed_key = "0cee6f373c3570abb470e27dbe048b54"
),

stops_on_day AS (
    SELECT
        trips.service_date,
        trips.feed_key,
        trips.feed_timezone,
        stop_id,

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
    INNER JOIN stop_times_grouped
        ON trips.feed_key = stop_times_grouped.feed_key
        AND trips.trip_id = stop_times_grouped.trip_id
    LEFT JOIN UNNEST(stop_times_grouped.stop_id_array) AS stop_id
    GROUP BY 1, 2, 3, 4
),

fct_daily_scheduled_stops AS (
    SELECT

        {{ dbt_utils.generate_surrogate_key(['stops_on_day.service_date', 'stops.key']) }} AS key,

        stops_on_day.service_date,
        stops_on_day.feed_key,
        stops_on_day.stop_id,
        stops_on_day.feed_timezone,

        arrivals.daily_arrivals, -- was stop_event_count,
        DATETIME(TIMESTAMP_ADD(
            {{ gtfs_noon_minus_twelve_hours('stops_on_day.service_date', 'stops_on_day.feed_timezone') }},
            INTERVAL arrivals.min_arrival_sec SECOND
        ), "America/Los_Angeles") AS first_stop_arrival_datetime_pacific,
        DATETIME(TIMESTAMP_ADD(
            {{ gtfs_noon_minus_twelve_hours('stops_on_day.service_date', 'stops_on_day.feed_timezone') }},
            INTERVAL arrivals.max_departure_sec SECOND
        ), "America/Los_Angeles") AS last_stop_departure_datetime_pacific,
        arrivals._feed_valid_from,

        arrivals.n_hours_in_service,
        arrivals.arrivals_per_hour_owl,
        arrivals.arrivals_per_hour_early_am,
        arrivals.arrivals_per_hour_am_peak,
        arrivals.arrivals_per_hour_midday,
        arrivals.arrivals_per_hour_pm_peak,
        arrivals.arrivals_per_hour_evening,

        arrivals.route_type_0,
        arrivals.route_type_1,
        arrivals.route_type_2,
        arrivals.route_type_3,
        arrivals.route_type_4,
        arrivals.route_type_5,
        arrivals.route_type_6,
        arrivals.route_type_7,
        arrivals.route_type_11,
        arrivals.route_type_12,
        arrivals.missing_route_type,

        arrivals.route_type_array,
        arrivals.route_id_array,
        ARRAY_LENGTH(arrivals.route_type_array) AS n_route_types,

        stops_on_day.contains_warning_duplicate_stop_times_primary_key,
        stops_on_day.contains_warning_duplicate_trip_primary_key,
        stops_on_day.contains_warning_missing_foreign_key_stop_id,

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

    FROM stops_on_day
    INNER JOIN dim_stops AS stops
        ON stops_on_day.feed_key = stops.feed_key
        AND stops_on_day.stop_id = stops.stop_id
    LEFT JOIN dim_stop_arrivals AS arrivals
        ON stops.feed_key = arrivals.feed_key
        AND stops.stop_id = arrivals.stop_id
)

SELECT * FROM fct_daily_scheduled_stops
