{{
    config(
        materialized='table',
        cluster_by=['service_date']
    )
}}

WITH daily_schedule AS (
    SELECT *
    FROM `cal-itp-data-infra.mart_gtfs.fct_daily_feed_scheduled_service_summary` --{{ ref('fct_daily_feed_scheduled_service_summary') }}
    WHERE service_date >= "2025-09-01"
),

daily_rt AS (
    SELECT *
    FROM `cal-itp-data-infra-staging.tiffany_mart_gtfs.test_fct_daily_rt_service_summary`
),

daily_summary AS (
    SELECT
        daily_schedule.service_date,
        daily_schedule.feed_key,
        daily_schedule.gtfs_dataset_key,
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
        daily_rt.schedule_name,
        daily_rt.vp_gtfs_dataset_key,
        daily_rt.vp_name,
        daily_rt.vp_base64_url,
        daily_rt.tu_gtfs_dataset_key,
        daily_rt.tu_name,
        daily_rt.tu_base64_url,

        daily_rt.vp_messages_per_minute,
        COALESCE(daily_rt.n_vp_trips, 0) AS n_vp_trips,
        ROUND(SAFE_DIVIDE(daily_rt.n_vp_trips, daily_schedule.n_trips), 3) AS pct_vp_trips,
        -- of total scheduled service minutes, how many was approx covered with vp
        ROUND(SAFE_DIVIDE(vp_extract_duration_minutes, ttl_service_hours * 60), 3) AS pct_vp_service_hours,

        -- trip updates
        daily_rt.tu_messages_per_minute,
        COALESCE(daily_rt.n_tu_trips, 0) AS n_tu_trips,
        ROUND(SAFE_DIVIDE(daily_rt.n_tu_trips, daily_schedule.n_trips), 3) AS pct_tu_trips,
        -- of total scheduled service minutes, how many was approx covered with tu
        ROUND(SAFE_DIVIDE(tu_extract_duration_minutes, ttl_service_hours * 60), 3) AS pct_tu_service_hours,

        -- saw that some operators had only vp but not tu, so let's differentiate
        CASE
            WHEN n_trips > 0 AND n_tu_trips = 0 AND n_vp_trips = 0 THEN "schedule_only"
            WHEN n_tu_trips > 0 AND n_vp_trips > 0 THEN "schedule_and_rt"
            WHEN n_tu_trips > 0 AND n_vp_trips = 0 THEN "schedule_and_tu_only"
            WHEN n_tu_trips = 0 AND n_vp_trips > 0 THEN "schedule_and_vp_only"
            ELSE "unknown"
        END AS gtfs_availability,

    FROM daily_schedule
    LEFT JOIN daily_rt
        ON daily_schedule.service_date = daily_rt.service_date
        AND daily_schedule.gtfs_dataset_name = daily_rt.schedule_name
        AND daily_schedule.gtfs_dataset_key = daily_rt.schedule_gtfs_dataset_key
        -- joining on schedule_base64_url might cause some observed_trips to not match
        -- how should we handle moving across quartets?
        -- joining on name will cause fanout (ex:)
        -- if we add analysis_name here, there will be cases that are confusing, nulls (ex):
)

SELECT * FROM daily_summary
