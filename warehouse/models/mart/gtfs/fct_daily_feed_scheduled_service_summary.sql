{{ config(materialized='table') }}

WITH fct_daily_schedule_feeds AS (
    SELECT
        *,
        EXTRACT(DAYOFWEEK FROM date) AS day_num
    FROM {{ ref('fct_daily_schedule_feeds') }}
),

fct_scheduled_trips AS (

    SELECT *
    FROM {{ ref('fct_scheduled_trips') }}

),

-- service that is actually scheduled
summarize_service AS (

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
    WHERE service_date < CURRENT_DATE()
    GROUP BY service_date, feed_key, gtfs_dataset_key
),

-- left join with feeds to include information about feeds with no service scheduled
fct_daily_feed_scheduled_service_summary AS (

    SELECT
        feeds.date AS service_date,
        feeds.feed_key,
        feeds.gtfs_dataset_key,
        COALESCE(service.ttl_service_hours, 0) AS ttl_service_hours,
        COALESCE(service.n_trips, 0) AS n_trips,
        service.first_departure_sec,
        service.last_arrival_sec,
        COALESCE(service.num_stop_times, 0) AS num_stop_times,
        COALESCE(service.n_routes, 0) AS n_routes,
        service.contains_warning_duplicate_stop_times_primary_key,
        service.contains_warning_duplicate_trip_primary_key,
        service.contains_warning_missing_foreign_key_stop_id
    FROM fct_daily_schedule_feeds AS feeds
    LEFT JOIN summarize_service AS service
        ON feeds.feed_key = service.feed_key
        AND feeds.date = service.service_date
)

SELECT * FROM fct_daily_feed_scheduled_service_summary
