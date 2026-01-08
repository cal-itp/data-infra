{{
    config(
        materialized='table'
    )
}}

WITH dim_stop_times AS (
    SELECT *
    FROM `cal-itp-data-infra-staging.tiffany_mart_gtfs.dim_stop_times_testing`
    WHERE feed_key = "0cee6f373c3570abb470e27dbe048b54"
),

int_gtfs_schedule__frequencies_stop_times AS (
    SELECT *
    FROM `cal-itp-data-infra-staging.tiffany_staging.int_gtfs_schedule__frequencies_stop_times_testing`
    WHERE feed_key = "0cee6f373c3570abb470e27dbe048b54" AND stop_id IS NOT NULL
),

dim_trips AS (
    SELECT DISTINCT
        feed_key,
        trip_id,
        route_id
    FROM `cal-itp-data-infra-staging.tiffany_mart_gtfs.dim_trips_testing`
    WHERE feed_key = "0cee6f373c3570abb470e27dbe048b54"
),

dim_routes AS (
    SELECT DISTINCT
        feed_key,
        route_id,
        route_type
    FROM `cal-itp-data-infra-staging.tiffany_mart_gtfs.dim_routes_testing`
    WHERE feed_key = "0cee6f373c3570abb470e27dbe048b54"
),

-- without select distinct or groupby, this join creates dupe rows....why?
-- which column is missing from join?
-- iteration_num values differ because of freq-based trips, and I think we want to count
-- all the unique trip_ids
stop_times_with_freq AS (
    SELECT
        stop_times.feed_key,
        stop_times.stop_id,
        stop_times.feed_timezone,
        stop_times.stop_sequence,
        stop_times.trip_id,
        MAX(stop_times._feed_valid_from) as _feed_valid_from,

        dim_routes.route_id,
        COALESCE(CAST(dim_routes.route_type AS INT), 1000) AS route_type,

        MIN(COALESCE(arrival_sec, stop_times_arrival_sec)) AS arrival_sec,
        MAX(COALESCE(departure_sec, stop_times_departure_sec)) AS departure_sec,

    FROM dim_stop_times AS stop_times
    LEFT JOIN int_gtfs_schedule__frequencies_stop_times AS freq
        ON stop_times.feed_key = freq.feed_key
        AND stop_times._feed_valid_from = freq._feed_valid_from
        AND stop_times.trip_id = freq.trip_id
        AND stop_times.stop_id = freq.stop_id
        AND stop_times.stop_sequence = freq.stop_sequence
    LEFT JOIN dim_trips
        ON stop_times.feed_key = dim_trips.feed_key
        AND stop_times.trip_id = dim_trips.trip_id
    INNER JOIN dim_routes
        ON dim_trips.feed_key = dim_routes.feed_key
        AND dim_trips.route_id = dim_routes.route_id
    GROUP BY feed_key, feed_timezone, trip_id, route_id, route_type, stop_id, stop_sequence
),

-- stop_time counts aggregated for the day
stop_counts AS (
    SELECT
        feed_key,
        feed_timezone,
        stop_id,
        MAX(_feed_valid_from) AS _feed_valid_from,

        COUNT(DISTINCT arrival_sec) AS arrivals,
        COUNT(DISTINCT
            CAST(TRUNC(arrival_sec / 3600) AS INT
        )) AS n_hours_in_service,
        MIN(arrival_sec) AS min_arrival_sec,
        MAX(departure_sec) AS max_departure_sec,
        ARRAY_AGG(DISTINCT route_type) AS route_type_array,
        ARRAY_AGG(DISTINCT route_id IGNORE NULLS) AS route_id_array,
    FROM stop_times_with_freq
    WHERE arrival_sec IS NOT NULL
    GROUP BY feed_key, feed_timezone, stop_id
),

-- stop_time by arrival_hour, then aggregate up to time-of-day
stop_counts_by_hour AS (
    SELECT
        feed_key,
        stop_id,
        CAST(
          TRUNC(arrival_sec / 3600) AS INT
        ) AS arrival_hour,

        COUNT(*) AS arrivals,

    FROM stop_times_with_freq
    GROUP BY feed_key, stop_id, arrival_hour
),


-- get counts aggregated to time-of-day
stop_counts_by_time_of_day AS (
    SELECT
        feed_key,
        stop_id,
        {{ generate_time_of_day_column('arrival_hour') }} AS time_of_day,
        SUM(arrivals) AS arrivals
    FROM stop_counts_by_hour
    WHERE arrival_hour IS NOT NULL
    GROUP BY feed_key, stop_id, time_of_day
),

stop_counts_by_time_of_day2 AS (
    SELECT
        *,
        -- can we call macro within another macro? write as 2 lines here
        -- https://docs.getdbt.com/best-practices/dont-nest-your-curlies
        {{ generate_time_of_day_hours('time_of_day') }} AS n_hours,

    FROM stop_counts_by_time_of_day
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

        FROM stop_counts_by_time_of_day2)
    PIVOT(
        SUM(arrivals) AS arrivals,
        SUM(n_hours) AS n_hours
        FOR time_of_day IN
        ("owl", "early_am", "am_peak", "midday", "pm_peak", "evening")
    )
),

-- also get route_type, route_ids
stop_counts_by_route_type AS (
    SELECT
        feed_key,
        stop_id,
        route_type,
        COUNT(*) AS arrivals,

    FROM stop_times_with_freq
    GROUP BY feed_key, stop_id, route_type
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

dim_stop_arrivals AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['stop_counts.feed_key', 'stop_counts.stop_id', 'stop_counts._feed_valid_from']) }} AS key,
        {{ dbt_utils.generate_surrogate_key(['stop_counts.feed_key', 'stop_counts.stop_id']) }} AS _gtfs_key,
        stop_counts.feed_key,
        stop_counts.stop_id,
        stop_counts.feed_timezone,
        stop_counts._feed_valid_from,
        stop_counts.arrivals AS daily_arrivals,
        stop_counts.min_arrival_sec,
        stop_counts.max_departure_sec,
        stop_counts.route_type_array,
        stop_counts.route_id_array,

        -- even if stop wraps service past midnight, this is capped at 24
        CASE
            WHEN stop_counts.n_hours_in_service >= 24 THEN 24
            ELSE stop_counts.n_hours_in_service
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

    FROM stop_counts
    INNER JOIN pivot_to_time_of_day AS p_time
        ON stop_counts.feed_key = p_time.feed_key
        AND stop_counts.stop_id = p_time.stop_id
    INNER JOIN pivot_to_route_type AS p_route
        ON stop_counts.feed_key = p_route.feed_key
        AND stop_counts.stop_id = p_route.stop_id
)

SELECT * FROM dim_stop_arrivals

-- job ID (use 1 big left join in the front): 8efa598c-578a-4bf5-9267-d2442e34f38b
-- more compact: elapsed time: 34.22 sec; 213.33 GB; 3 hr 44 min slot time

-- job ID (move some joins out): 5ee1020c-d445-4d65-92f1-12697fce895c
-- more sprawling: elapsed time: 38.4 sec; 250.15 GB; 5 hr 32 min slot time
