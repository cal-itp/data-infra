{{
    config(
        materialized='table',
        cluster_by='base64_url',
    )
}}


WITH service_alerts AS (
    SELECT *,
            -- https://gtfs.org/realtime/reference/#message-tripdescriptor
        {{ dbt_utils.generate_surrogate_key([
            'calculated_service_date',
            'base64_url',
            'trip_id',
            'trip_start_time',
        ]) }} as key,
    FROM {{ ref('int_gtfs_rt__service_alerts_trip_day_map_grouping') }}
),

window_functions AS (
    SELECT *,
        FIRST_VALUE(trip_schedule_relationship)
        OVER (
            PARTITION BY key
            ORDER BY min_header_timestamp
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS starting_schedule_relationship,
    LAST_VALUE(trip_schedule_relationship)
        OVER (
            PARTITION BY key
            ORDER BY max_header_timestamp
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS ending_schedule_relationship,
    FIRST_VALUE(trip_direction_id)
        OVER (
            PARTITION BY key
            ORDER BY min_header_timestamp
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS starting_direction_id,
    LAST_VALUE(trip_direction_id)
        OVER (
            PARTITION BY key
            ORDER BY max_header_timestamp
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS ending_direction_id,
    FROM service_alerts
),

message_ids AS (
    {{ gtfs_rt_unnest_column_count_distinct(table = 'service_alerts',
    key_col = 'key',
    array_col = 'message_ids_array',
    output_column_name = 'num_distinct_message_ids') }}
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

distinct_alert_content AS (
    SELECT DISTINCT
        key,
        unnested_alert_content
    FROM service_alerts
    LEFT JOIN UNNEST(alert_content_array) AS unnested_alert_content
),

reaggregate_alert_content AS (
    SELECT
        key,
        ARRAY_AGG(
            STRUCT<message_id string, cause string, effect string, header string, description string >
                (JSON_VALUE(unnested_alert_content, '$.message_id'),
                JSON_VALUE(unnested_alert_content, '$.cause'),
                JSON_VALUE(unnested_alert_content, '$.effect'),
                JSON_VALUE(unnested_alert_content, '$.header'),
                JSON_VALUE(unnested_alert_content, '$.description')))
        AS alert_content_array
    FROM distinct_alert_content
    GROUP BY 1
),

non_array_agg AS(
     SELECT
        -- https://gtfs.org/realtime/reference/#message-tripdescriptor
        key,
        calculated_service_date,
        base64_url,
        trip_id,
        trip_route_id,
        trip_start_time,
        trip_start_date,
        feed_timezone,
        starting_schedule_relationship,
        ending_schedule_relationship,
        starting_direction_id,
        ending_direction_id,
        MIN(min_extract_ts) AS min_extract_ts,
        MAX(max_extract_ts) AS max_extract_ts,
        MIN(min_header_timestamp) AS min_header_timestamp,
        MAX(max_header_timestamp) AS max_header_timestamp,
    FROM window_functions
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12
),

fct_service_alerts_trip_summaries AS (
    SELECT
        key,
        calculated_service_date,
        base64_url,
        trip_id,
        trip_start_time,
        trip_start_date,
        feed_timezone,
        starting_schedule_relationship,
        ending_schedule_relationship,
        starting_direction_id,
        ending_direction_id,
        starting_route_id,
        ending_route_id,
        starting_direction_id,
        ending_direction_id,
        min_extract_ts,
        max_extract_ts,
        TIMESTAMP_DIFF(max_extract_ts, min_extract_ts, MINUTE) AS extract_duration_minutes,
        DATETIME(min_extract_ts, "America/Los_Angeles") AS min_extract_datetime_pacific,
        DATETIME(max_extract_ts, "America/Los_Angeles") AS max_extract_datetime_pacific,
        DATETIME(min_extract_ts, feed_timezone) AS min_extract_datetime_local_tz,
        DATETIME(max_extract_ts, feed_timezone) AS max_extract_datetime_local_tz,
        min_header_timestamp,
        max_header_timestamp,
        TIMESTAMP_DIFF(max_header_timestamp, min_header_timestamp, MINUTE) AS header_duration_minutes,
        DATETIME(min_extract_ts, "America/Los_Angeles") AS min_header_datetime_pacific,
        DATETIME(max_extract_ts, "America/Los_Angeles") AS max_header_datetime_pacific,
        DATETIME(min_extract_ts, feed_timezone) AS min_header_datetime_local_tz,
        DATETIME(max_extract_ts, feed_timezone) AS max_header_datetime_local_tz,
        num_distinct_message_ids,
        num_distinct_header_timestamps,
        num_distinct_message_keys,
        num_distinct_extract_ts,
        alert_content_array,
    FROM non_array_agg
    LEFT JOIN message_ids USING (key)
    LEFT JOIN header_timestamps USING (key)
    LEFT JOIN extract_ts USING (key)
    LEFT JOIN message_keys USING (key)
    LEFT JOIN reaggregate_alert_content USING (key)
)

SELECT * FROM fct_service_alerts_trip_summaries
