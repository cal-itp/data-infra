{{
    config(
        materialized='incremental',
        unique_key = 'key',
        partition_by = {
            'field': 'service_date',
            'data_type': 'date',
            'granularity': 'day',
        },
        cluster_by='feed_key',
    )
}}

WITH fct_scheduled_trips AS (
    SELECT
        service_date,
        feed_key,
        feed_timezone,
        trip_id,
        contains_warning_duplicate_stop_times_primary_key,
        contains_warning_duplicate_trip_primary_key,
        contains_warning_missing_foreign_key_stop_id
    FROM {{ ref('fct_scheduled_trips') }}
    WHERE {{ incremental_where(default_start_var='GTFS_SCHEDULE_START',
                               this_dt_column='service_date',
                               filter_dt_column='service_date',
                               dev_lookback_days = None) }}
),

dim_stops AS (
    SELECT *
    FROM `cal-itp-data-infra.mart_gtfs.dim_stops`--{{ ref('dim_stops') }}
),

dim_stop_arrivals AS (
    SELECT *
    FROM {{ ref('dim_stop_arrivals') }}
),

stops_on_day_by_route_and_hour AS (
    SELECT
        trips.service_date,
        trips.feed_key,
        trips.feed_timezone,
        dim_stop_arrivals._feed_valid_from,
        dim_stop_arrivals.stop_id,

        dim_stop_arrivals.route_id,
        dim_stop_arrivals.route_type,
        dim_stop_arrivals.arrival_hour,
        {{ generate_time_of_day_column('arrival_hour') }} AS time_of_day,

        COUNT(*) AS arrivals,
        MIN(DATETIME(TIMESTAMP_ADD(
            {{ gtfs_noon_minus_twelve_hours('trips.service_date', 'trips.feed_timezone') }},
            INTERVAL dim_stop_arrivals.arrival_sec SECOND
        ), "America/Los_Angeles")) AS first_stop_arrival_datetime_pacific,
        MAX(DATETIME(TIMESTAMP_ADD(
            {{ gtfs_noon_minus_twelve_hours('trips.service_date', 'trips.feed_timezone') }},
            INTERVAL dim_stop_arrivals.departure_sec SECOND
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
    INNER JOIN dim_stop_arrivals
        ON trips.feed_key = dim_stop_arrivals.feed_key
        AND trips.trip_id = dim_stop_arrivals.trip_id
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9
),

stops_on_day AS (
    SELECT
        service_date,
        feed_key,
        feed_timezone,
        _feed_valid_from,
        stop_id,

        SUM(arrivals) AS daily_arrivals, -- was stop_event_count,
        MIN(first_stop_arrival_datetime_pacific) AS first_stop_arrival_datetime_pacific,
        MAX(last_stop_departure_datetime_pacific) AS last_stop_departure_datetime_pacific,
        COUNT(DISTINCT arrival_hour) AS n_hours_in_service,

        ARRAY_AGG(DISTINCT route_id) AS route_id_array,
        ARRAY_AGG(DISTINCT route_type) AS route_type_array,

        LOGICAL_OR(
            contains_warning_duplicate_stop_times_primary_key
        ) AS contains_warning_duplicate_stop_times_primary_key,
        LOGICAL_OR(
            contains_warning_duplicate_trip_primary_key
        ) AS contains_warning_duplicate_trip_primary_key,
        LOGICAL_OR(
            contains_warning_missing_foreign_key_stop_id
        ) AS contains_warning_missing_foreign_key_stop_id,
    FROM stops_on_day_by_route_and_hour
    GROUP BY 1, 2, 3, 4, 5
),

stop_counts_by_route_type AS (
    SELECT
        feed_key,
        stop_id,
        route_type,
        COUNT(*) AS arrivals
    FROM stops_on_day_by_route_and_hour
    GROUP BY 1, 2, 3
),

pivot_to_route_type AS (

    SELECT *
    FROM
        (SELECT

            feed_key,
            stop_id,
            route_type,
            arrivals,

        FROM stop_counts_by_route_type)
    PIVOT(
        SUM(arrivals) AS route_type
        FOR route_type IN
        (0, 1, 2, 3, 4, 5, 6, 7, 11, 12, 1000)
    )
),

stop_counts_by_time_of_day AS (
    SELECT
        feed_key,
        stop_id,
        time_of_day,
        {{ generate_time_of_day_hours('time_of_day') }} AS n_hours,

        COUNT(*) AS arrivals
    FROM stops_on_day_by_route_and_hour
    GROUP BY 1, 2, 3, 4
),

pivot_to_time_of_day AS (

    SELECT *
    FROM
        (SELECT

            feed_key,
            stop_id,
            time_of_day,
            arrivals,
            n_hours

        FROM stop_counts_by_time_of_day)
    PIVOT(
        SUM(arrivals) AS arrivals,
        SUM(n_hours) AS n_hours
        FOR time_of_day IN
        ("owl", "early_am", "am_peak", "midday", "pm_peak", "evening")
    )
),

fct_daily_scheduled_stops AS (
    SELECT
       {{ dbt_utils.generate_surrogate_key(['stops_on_day.service_date', 'stops.key']) }} AS key,

        stops_on_day.service_date,
        stops_on_day.feed_key,
        stops_on_day.stop_id,
        stops_on_day.feed_timezone,
        stops_on_day.daily_arrivals,
        stops_on_day.first_stop_arrival_datetime_pacific,
        stops_on_day.last_stop_departure_datetime_pacific,
        stops_on_day._feed_valid_from,

        -- even if stop wraps service past midnight, this is capped at 24
        CASE
            WHEN stops_on_day.n_hours_in_service >= 24 THEN 24
            ELSE stops_on_day.n_hours_in_service
        END AS n_hours_in_service,

       -- operators can have arrivals in certain time-of-day periods and not others
        -- arrivals_per_hour averaged with these values will differ than
        -- daily arrivals / 24.
        -- n_hours_in_service shows just how many unique arrival_hours the operator does have service
        COALESCE(ROUND(p_time.arrivals_owl / p_time.n_hours_owl, 1), 0) AS arrivals_per_hour_owl,
        COALESCE(ROUND(p_time.arrivals_early_am / p_time.n_hours_early_am, 1), 0) AS arrivals_per_hour_early_am,
        COALESCE(ROUND(p_time.arrivals_am_peak / p_time.n_hours_am_peak, 1), 0) AS arrivals_per_hour_am_peak,
        COALESCE(ROUND(p_time.arrivals_midday / p_time.n_hours_midday, 1), 0) AS arrivals_per_hour_midday,
        COALESCE(ROUND(p_time.arrivals_pm_peak / p_time.n_hours_pm_peak, 1), 0) AS arrivals_per_hour_pm_peak,
        COALESCE(ROUND(p_time.arrivals_evening / p_time.n_hours_evening, 1), 0) AS arrivals_per_hour_evening,

        COALESCE(p_time.arrivals_owl, 0) AS arrivals_owl,
        COALESCE(p_time.arrivals_early_am, 0) AS arrivals_early_am,
        COALESCE(p_time.arrivals_am_peak, 0) AS arrivals_am_peak,
        COALESCE(p_time.arrivals_midday, 0) AS arrivals_midday,
        COALESCE(p_time.arrivals_pm_peak, 0) AS arrivals_pm_peak,
        COALESCE(p_time.arrivals_evening, 0) AS arrivals_evening,

        COALESCE(p_route.route_type_0, 0) AS route_type_0,
        COALESCE(p_route.route_type_1, 0) AS route_type_1,
        COALESCE(p_route.route_type_2, 0) AS route_type_2,
        COALESCE(p_route.route_type_3, 0) AS route_type_3,
        COALESCE(p_route.route_type_4, 0) AS route_type_4,
        COALESCE(p_route.route_type_5, 0) AS route_type_5,
        COALESCE(p_route.route_type_6, 0) AS route_type_6,
        COALESCE(p_route.route_type_7, 0) AS route_type_7,
        COALESCE(p_route.route_type_11, 0) AS route_type_11,
        COALESCE(p_route.route_type_12, 0) AS route_type_12,
        COALESCE(p_route.route_type_1000, 0) AS missing_route_type,

        stops_on_day.contains_warning_duplicate_stop_times_primary_key,
        stops_on_day.contains_warning_duplicate_trip_primary_key,
        stops_on_day.route_id_array,
        stops_on_day.route_type_array,
        ARRAY_LENGTH(stops_on_day.route_type_array) AS n_route_types,

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
    LEFT JOIN pivot_to_time_of_day AS p_time
        ON stops_on_day.feed_key = p_time.feed_key
        AND stops_on_day.stop_id = p_time.stop_id
    LEFT JOIN pivot_to_route_type AS p_route
        ON stops_on_day.feed_key = p_route.feed_key
        AND stops_on_day.stop_id = p_route.stop_id
)

SELECT * FROM fct_daily_scheduled_stops
