{{
    config(
        materialized='incremental',
        incremental_strategy = 'insert_overwrite',
        partition_by = {
            'field': 'service_date',
            'data_type': 'date',
            'granularity': 'day',
        },
        cluster_by='feed_key',
    )
}}

with stops_on_day_by_route_and_hour AS (
    SELECT
        trips.service_date,
        trips.feed_key,
        trips.feed_timezone,
        dim_stop_arrivals._feed_valid_from,
        dim_stop_arrivals.stop_id,

        {{ parse_route_id('name', 'dim_stop_arrivals.route_id') }} AS route_id,
        dim_stop_arrivals.route_type,

        (SELECT CASE
              WHEN dim_stop_arrivals.route_type IN (0, 1, 2) THEN "rail"
              WHEN dim_stop_arrivals.route_type = 3 THEN "bus"
              WHEN dim_stop_arrivals.route_type = 4 THEN "ferry"
              WHEN dim_stop_arrivals.route_type IN (5, 6, 7, 12) THEN "other_rail"
              WHEN dim_stop_arrivals.route_type = 11 THEN "trolleybus"
            END) AS transit_mode,

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
        ) AS contains_warning_missing_foreign_key_stop_id

    FROM {{ ref('fct_scheduled_trips') }} AS trips
    INNER JOIN {{ ref('dim_stop_arrivals') }} AS dim_stop_arrivals
       ON trips.feed_key = dim_stop_arrivals.feed_key
      AND trips.trip_id = dim_stop_arrivals.trip_id
    WHERE trips.service_date
        BETWEEN {{ ranged_incremental_min_date(default_lookback=var("DBT_ALL_INCREMENTAL_LOOKBACK_DAYS"), data_earliest_start=var("GTFS_SCHEDULE_START")) }}
            AND {{ ranged_incremental_max_date() }}
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
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

        ARRAY_AGG(DISTINCT route_id ORDER BY route_id) AS route_id_array,
        ARRAY_AGG(DISTINCT route_type ORDER BY route_type) AS route_type_array,
        ARRAY_AGG(DISTINCT transit_mode ORDER BY transit_mode) AS transit_mode_array,

        SUM(IF(route_type = 0, arrivals, 0)) AS route_type_0,
        SUM(IF(route_type = 1, arrivals, 0)) AS route_type_1,
        SUM(IF(route_type = 2, arrivals, 0)) AS route_type_2,
        SUM(IF(route_type = 3, arrivals, 0)) AS route_type_3,
        SUM(IF(route_type = 4, arrivals, 0)) AS route_type_4,
        SUM(IF(route_type = 5, arrivals, 0)) AS route_type_5,
        SUM(IF(route_type = 6, arrivals, 0)) AS route_type_6,
        SUM(IF(route_type = 7, arrivals, 0)) AS route_type_7,
        SUM(IF(route_type = 11, arrivals, 0)) AS route_type_11,
        SUM(IF(route_type = 12, arrivals, 0)) AS route_type_12,
        SUM(IF(route_type = 1000, arrivals, 0)) AS route_type_1000,

        SUM(IF(time_of_day = 'owl', arrivals, 0)) AS arrivals_owl,
        SUM(IF(time_of_day = 'early_am', arrivals, 0)) AS arrivals_early_am,
        SUM(IF(time_of_day = 'am_peak', arrivals, 0)) AS arrivals_am_peak,
        SUM(IF(time_of_day = 'midday', arrivals, 0)) AS arrivals_midday,
        SUM(IF(time_of_day = 'pm_peak', arrivals, 0)) AS arrivals_pm_peak,
        SUM(IF(time_of_day = 'evening', arrivals, 0)) AS arrivals_evening,

        LOGICAL_OR(
            contains_warning_duplicate_stop_times_primary_key
        ) AS contains_warning_duplicate_stop_times_primary_key,
        LOGICAL_OR(
            contains_warning_duplicate_trip_primary_key
        ) AS contains_warning_duplicate_trip_primary_key,
        LOGICAL_OR(
            contains_warning_missing_foreign_key_stop_id
        ) AS contains_warning_missing_foreign_key_stop_id
    FROM stops_on_day_by_route_and_hour
    GROUP BY 1, 2, 3, 4, 5
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
        COALESCE(ROUND(stops_on_day.arrivals_owl / 4, 1), 0) AS arrivals_per_hour_owl,
        COALESCE(ROUND(stops_on_day.arrivals_early_am / 3, 1), 0) AS arrivals_per_hour_early_am,
        COALESCE(ROUND(stops_on_day.arrivals_am_peak / 3, 1), 0) AS arrivals_per_hour_am_peak,
        COALESCE(ROUND(stops_on_day.arrivals_midday / 5, 1), 0) AS arrivals_per_hour_midday,
        COALESCE(ROUND(stops_on_day.arrivals_pm_peak / 5, 1), 0) AS arrivals_per_hour_pm_peak,
        COALESCE(ROUND(stops_on_day.arrivals_evening / 4, 1), 0) AS arrivals_per_hour_evening,

        stops_on_day.arrivals_owl AS arrivals_owl,
        stops_on_day.arrivals_early_am AS arrivals_early_am,
        stops_on_day.arrivals_am_peak AS arrivals_am_peak,
        stops_on_day.arrivals_midday AS arrivals_midday,
        stops_on_day.arrivals_pm_peak AS arrivals_pm_peak,
        stops_on_day.arrivals_evening AS arrivals_evening,

        stops_on_day.route_type_0 AS route_type_0,
        stops_on_day.route_type_1 AS route_type_1,
        stops_on_day.route_type_2 AS route_type_2,
        stops_on_day.route_type_3 AS route_type_3,
        stops_on_day.route_type_4 AS route_type_4,
        stops_on_day.route_type_5 AS route_type_5,
        stops_on_day.route_type_6 AS route_type_6,
        stops_on_day.route_type_7 AS route_type_7,
        stops_on_day.route_type_11 AS route_type_11,
        stops_on_day.route_type_12 AS route_type_12,
        stops_on_day.route_type_1000 AS missing_route_type,

        stops_on_day.route_id_array,
        stops_on_day.route_type_array,
        ARRAY_LENGTH(stops_on_day.route_type_array) AS n_route_types,

        stops_on_day.transit_mode_array,

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

        stops_on_day.contains_warning_duplicate_stop_times_primary_key,
        stops_on_day.contains_warning_duplicate_trip_primary_key,

        stops.warning_duplicate_gtfs_key AS contains_warning_duplicate_stop_primary_key,

        (stops_on_day.n_hours_in_service > 24) AS contains_warning_hours_in_service_more_than_24,

        ( arrivals_owl + arrivals_early_am
          + arrivals_am_peak + arrivals_midday
          + arrivals_pm_peak + arrivals_evening
        ) != daily_arrivals AS contains_warning_wrong_total_arrivals_time_of_day,

        ( route_type_0 + route_type_1 + route_type_2
          + route_type_3 + route_type_4 + route_type_5
          + route_type_6 + route_type_7 + route_type_11
          + route_type_12 + route_type_1000
        ) != daily_arrivals AS contains_warning_wrong_total_arrivals_route_type

    FROM stops_on_day
    INNER JOIN {{ ref('dim_stops') }} AS stops
        ON stops_on_day.feed_key = stops.feed_key
        AND stops_on_day.stop_id = stops.stop_id
)

SELECT * FROM fct_daily_scheduled_stops
