{{
    config(
        materialized='table',
        cluster_by='base64_url',
    )
}}

WITH service_alerts AS (
    SELECT *
    FROM {{ ref('int_gtfs_rt__service_alerts_day_map_grouping') }}
),

header_timestamps AS (
    {{ gtfs_rt_unnest_column_count_distinct(table = 'service_alerts',
    key_col = 'key',
    array_col = 'header_timestamps_array',
    output_column_name = 'num_distinct_header_timestamps') }}
),

extract_ts AS (
    {{ gtfs_rt_unnest_column_count_distinct(table = 'service_alerts',
    key_col = 'key',
    array_col = 'extract_ts_array',
    output_column_name = 'num_distinct_extract_ts') }}
),

message_keys AS (
    {{ gtfs_rt_unnest_column_count_distinct(table = 'service_alerts',
    key_col = 'key',
    array_col = 'message_keys_array',
    output_column_name = 'num_distinct_message_keys') }}
),

non_array_agg AS(
     SELECT
        -- https://gtfs.org/realtime/reference/#message-tripdescriptor
        key,
        dt,
        active_date,
        base64_url,
        schedule_feed_timezone,
        id,
        cause,
        effect,
        header,
        description,
        trip_id,
        trip_route_id,
        trip_direction_id,
        trip_start_time,
        trip_start_date,
        trip_schedule_relationship,
        agency_id,
        route_id,
        route_type,
        direction_id,
        stop_id,
        active_period_start,
        active_period_end,
        active_period_start_ts,
        active_period_end_ts,
        MIN(min_extract_ts) AS min_extract_ts,
        MAX(max_extract_ts) AS max_extract_ts,
        MIN(min_header_timestamp) AS min_header_timestamp,
        MAX(max_header_timestamp) AS max_header_timestamp,
    FROM service_alerts
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25
),

fct_daily_service_alerts AS (
    SELECT
        key,
        dt,
        active_date,
        base64_url,
        schedule_feed_timezone,
        id,
        cause,
        effect,
        header,
        description,
        trip_id,
        trip_route_id,
        trip_direction_id,
        trip_start_time,
        trip_start_date,
        trip_schedule_relationship,
        agency_id,
        route_id,
        route_type,
        direction_id,
        stop_id,
        active_period_start,
        active_period_end,
        active_period_start_ts,
        active_period_end_ts,
        min_extract_ts,
        max_extract_ts,
        min_header_timestamp,
        max_header_timestamp,
        TIMESTAMP_DIFF(max_extract_ts, min_extract_ts, MINUTE) AS extract_duration_minutes,
        DATETIME(min_extract_ts, "America/Los_Angeles") AS min_extract_datetime_pacific,
        DATETIME(max_extract_ts, "America/Los_Angeles") AS max_extract_datetime_pacific,
        DATETIME(min_extract_ts, schedule_feed_timezone) AS min_extract_datetime_local_tz,
        DATETIME(max_extract_ts, schedule_feed_timezone) AS max_extract_datetime_local_tz,
        TIMESTAMP_DIFF(max_header_timestamp, min_header_timestamp, MINUTE) AS header_duration_minutes,
        DATETIME(min_header_timestamp, "America/Los_Angeles") AS min_header_datetime_pacific,
        DATETIME(max_header_timestamp, "America/Los_Angeles") AS max_header_datetime_pacific,
        DATETIME(min_header_timestamp, schedule_feed_timezone) AS min_header_datetime_local_tz,
        DATETIME(max_header_timestamp, schedule_feed_timezone) AS max_header_datetime_local_tz,
        num_distinct_header_timestamps,
        num_distinct_message_keys,
        num_distinct_extract_ts,
    FROM non_array_agg
    LEFT JOIN header_timestamps USING (key)
    LEFT JOIN extract_ts USING (key)
    LEFT JOIN message_keys USING (key)
)

SELECT * FROM fct_daily_service_alerts
