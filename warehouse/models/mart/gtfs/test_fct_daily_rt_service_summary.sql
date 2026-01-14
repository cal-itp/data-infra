{{
    config(
        materialized='table',
        cluster_by=['service_date']
    )
}}

WITH fct_observed_trips AS (
    SELECT *
    FROM `cal-itp-data-infra.mart_gtfs.fct_observed_trips`
    WHERE service_date >= "2025-09-01"--{{ ref('fct_observed_trips' )}}
),

observed_trips AS (
    SELECT
        *,
        -- num_distinct_message_keys = num_distinct_extract_ts and
        -- num_distinct_message_keys / extract_duration_minutes = messages per minute this entity was present for, how continuously this trip was updated.
        SAFE_DIVIDE(vp_num_distinct_extract_ts, vp_extract_duration_minutes) AS vp_messages_per_minute,
        SAFE_DIVIDE(tu_num_distinct_extract_ts, tu_extract_duration_minutes) AS tu_messages_per_minute,
    FROM fct_observed_trips
),

summarize_service AS (
    SELECT
        service_date,
        schedule_base64_url,
        -- found North County Trip Updates which had only schedule_base64_url and nulls for key and name
        MAX(schedule_gtfs_dataset_key) AS schedule_gtfs_dataset_key,
        MAX(schedule_name) AS schedule_name,

        -- there can be trip_instance_keys where vp is present but not tu and vice versa
        -- if they share the same schedule_name, fill it in, since we're aggregating
        -- to operator.
        MAX(vp_gtfs_dataset_key) AS vp_gtfs_dataset_key,
        MAX(vp_name) AS vp_name,
        MAX(vp_base64_url) AS vp_base64_url,
        MAX(tu_gtfs_dataset_key) AS tu_gtfs_dataset_key,
        MAX(tu_name) AS tu_name,
        MAX(tu_base64_url) AS tu_base64_url,

        -- vehicle positions
        -- take average of vp per minute, every trip is equally weighted
        ROUND(AVG(vp_messages_per_minute), 2) AS vp_messages_per_minute,
        -- follow fct_daily_trip_updates_vehicle_positions_completeness
        COALESCE(COUNTIF(vp_num_distinct_message_ids > 0), 0) AS n_vp_trips,
        SUM(vp_extract_duration_minutes) AS vp_extract_duration_minutes,

        -- trip updates
        ROUND(AVG(tu_messages_per_minute), 2) AS tu_messages_per_minute,
        COALESCE(COUNTIF(tu_num_distinct_message_ids > 0), 0) AS n_tu_trips,
        SUM(tu_extract_duration_minutes) AS tu_extract_duration_minutes,

    FROM observed_trips
    GROUP BY service_date, schedule_base64_url
)

SELECT * FROM summarize_service
