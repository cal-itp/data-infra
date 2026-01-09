{{
    config(
        materialized='table',
        cluster_by = ['service_date']
    )
}}

WITH fct_daily_schedule_feeds AS (
    SELECT
        *,
        EXTRACT(DAYOFWEEK FROM date) AS day_num
    FROM {{ ref('fct_daily_schedule_feeds') }}

),

fct_scheduled_trips AS (
    SELECT *
    FROM {{ ref('fct_scheduled_trips') }}
    WHERE service_date < CURRENT_DATE()
),

fct_scheduled_stops AS (
    SELECT
        service_date,
        feed_key,
        stop_id,
    FROM {{ ref('fct_daily_scheduled_stops') }}
    WHERE service_date < CURRENT_DATE()
),

trip_summary AS (
    SELECT
        service_date,
        feed_key,
        gtfs_dataset_key,
        SUM(service_hours) AS ttl_service_hours,
        COUNT(DISTINCT trip_id) AS n_trips,
        MIN(trip_first_departure_sec) AS first_departure_sec,
        MAX(trip_last_arrival_sec) AS last_arrival_sec,
        SUM(num_stop_times) AS num_stop_times,
        COUNT(DISTINCT route_id) AS n_routes,
        COUNT(DISTINCT shape_id) AS n_shapes,
        LOGICAL_OR(
            contains_warning_duplicate_stop_times_primary_key
        ) AS contains_warning_duplicate_stop_times_primary_key,
        LOGICAL_OR(
            contains_warning_duplicate_trip_primary_key
        ) AS contains_warning_duplicate_trip_primary_key,
        LOGICAL_OR(
            contains_warning_missing_foreign_key_stop_id
        ) AS contains_warning_missing_foreign_key_stop_id
    FROM fct_scheduled_trips
    GROUP BY service_date, feed_key, gtfs_dataset_key
),

stop_summary AS (
    SELECT
        service_date,
        feed_key,
        COUNT(DISTINCT stop_id) AS n_stops
    FROM fct_scheduled_stops
    GROUP BY service_date, feed_key
),

-- left join with feeds to include information about feeds with no service scheduled
fct_daily_feed_scheduled_service_summary AS (

    SELECT
        DATE(feeds.date) AS service_date,
        feeds.feed_key,
        feeds.gtfs_dataset_key,
        feeds.gtfs_dataset_name,
        COALESCE(trips.ttl_service_hours, 0) AS ttl_service_hours,
        COALESCE(trips.n_trips, 0) AS n_trips,
        trips.first_departure_sec,
        trips.last_arrival_sec,
        COALESCE(trips.num_stop_times, 0) AS num_stop_times,
        COALESCE(trips.n_routes, 0) AS n_routes,
        COALESCE(trips.n_shapes, 0) AS n_shapes,
        COALESCE(stops.n_stops, 0) AS n_stops,
        trips.contains_warning_duplicate_stop_times_primary_key,
        trips.contains_warning_duplicate_trip_primary_key,
        trips.contains_warning_missing_foreign_key_stop_id
    FROM fct_daily_schedule_feeds AS feeds
    LEFT JOIN trip_summary AS trips
        ON feeds.feed_key = trips.feed_key
        AND feeds.date = trips.service_date
    LEFT JOIN stop_summary AS stops
        ON feeds.feed_key = stops.feed_key
        AND feeds.date = stops.service_date
)

SELECT * FROM fct_daily_feed_scheduled_service_summary
