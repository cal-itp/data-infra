{{
    config(
        materialized='table',
        cluster_by=['service_date']
    )
}}

WITH daily_schedule AS (
    SELECT *
    FROM {{ ref('fct_daily_feed_scheduled_service_summary') }}
),

daily_rt AS (
    SELECT *
    FROM {{ ref('fct_daily_rt_service_summary') }}
),

daily_summary AS (
    SELECT
        COALESCE(daily_schedule.service_date, daily_rt.service_date) AS service_date,
        daily_schedule.feed_key,
        daily_schedule.gtfs_dataset_key, -- should get rid of a set of these so schedule keys aren't doubled up...once we figure out how to tag cases
        daily_schedule.gtfs_dataset_name,
        daily_schedule.ttl_service_hours,
        daily_schedule.n_trips,
        daily_schedule.first_departure_sec,
        daily_schedule.last_arrival_sec,
        daily_schedule.num_stop_times,
        daily_schedule.n_routes,
        daily_schedule.n_shapes,
        daily_schedule.n_stops,
        daily_schedule.contains_warning_duplicate_stop_times_primary_key,
        daily_schedule.contains_warning_duplicate_trip_primary_key,
        daily_schedule.contains_warning_missing_foreign_key_stop_id,

        daily_rt.schedule_base64_url,
        daily_rt.schedule_gtfs_dataset_key,
        daily_rt.schedule_gtfs_dataset_name AS schedule_name,
        daily_rt.vp_gtfs_dataset_key,
        daily_rt.vp_name,
        daily_rt.vp_base64_url,
        daily_rt.tu_gtfs_dataset_key,
        daily_rt.tu_name,
        daily_rt.tu_base64_url,

        -- trip updates
        COALESCE(daily_rt.n_tu_trips, 0) AS n_tu_trips,
        ROUND(SAFE_DIVIDE(daily_rt.n_vp_trips, daily_schedule.n_trips), 3) AS pct_tu_trips,
        daily_rt.n_tu_routes,
        ROUND(SAFE_DIVIDE(daily_rt.n_tu_routes, daily_schedule.n_routes), 3) AS pct_tu_routes,
        daily_rt.tu_extract_duration_minutes,
        daily_rt.tu_messages_per_minute,

        -- vehicle positions
        daily_rt.vp_num_distinct_updates,
        COALESCE(daily_rt.n_vp_trips, 0) AS n_vp_trips,
        ROUND(SAFE_DIVIDE(daily_rt.n_vp_trips, daily_schedule.n_trips), 3) AS pct_vp_trips,
        daily_rt.n_vp_routes,
        ROUND(SAFE_DIVIDE(daily_rt.n_vp_routes, daily_schedule.n_routes), 3) AS pct_vp_routes,
        daily_rt.vp_extract_duration_minutes,
        daily_rt.vp_messages_per_minute,

        -- figure out which ones are missing
        IF(gtfs_dataset_name IS NULL AND daily_schedule.feed_key IS NULL AND schedule_gtfs_dataset_name IS NOT NULL, 1, 0) AS in_obs_only,

        -- saw that some operators had only vp but not tu, so let's differentiate
        CASE
            WHEN COALESCE(daily_schedule.n_trips, 0) > 0 AND COALESCE(n_tu_trips, 0) = 0 AND COALESCE(n_vp_trips, 0) = 0 THEN "schedule_only"
            WHEN COALESCE(daily_schedule.n_trips, 0) > 0 AND n_tu_trips > 0 AND n_vp_trips > 0 THEN "schedule_and_rt"
            WHEN COALESCE(daily_schedule.n_trips, 0) > 0 AND n_tu_trips > 0 AND n_vp_trips = 0 THEN "schedule_and_tu_only"
            WHEN COALESCE(daily_schedule.n_trips, 0) > 0 AND n_tu_trips = 0 AND n_vp_trips > 0 THEN "schedule_and_vp_only"
            WHEN COALESCE(daily_schedule.n_trips, 0) = 0 THEN "no_active_service"
            WHEN COALESCE(daily_schedule.n_trips, 0) = 0 AND (n_tu_trips > 0 OR n_vp_trips > 0) THEN "no_schedule_and_rt"
            -- there are rows with active service but quartet hasn't been implemented yet, these cover 2022-10-01 values and before
            WHEN gtfs_dataset_name IS NULL AND daily_schedule.feed_key IS NOT NULL THEN "v1_warehouse"
            ELSE "unknown"
        END AS gtfs_availability,

    FROM daily_schedule
    FULL OUTER JOIN daily_rt -- full outer join to see which ones don't match up
        ON daily_schedule.service_date = daily_rt.service_date
        AND daily_schedule.gtfs_dataset_name = daily_rt.schedule_gtfs_dataset_name
        AND daily_schedule.gtfs_dataset_key = daily_rt.schedule_gtfs_dataset_key
)

SELECT * FROM daily_summary
