{{
    config(
        materialized='incremental',
        incremental_strategy='insert_overwrite',
        partition_by={
            'field': 'calculated_service_date',
            'data_type': 'date',
            'granularity': 'day',
        },
        cluster_by='base64_url',
    )
}}

WITH vehicle_positions AS (
    SELECT * EXCEPT(trip_direction_id),
        CAST(trip_direction_id AS STRING) AS trip_direction_id,
        -- subtract one because row_number is 1-based count and in frequency-based schedule we use 0-based
        DENSE_RANK() OVER (PARTITION BY
            base64_url,
            calculated_service_date,
            trip_id
            ORDER BY trip_start_time) - 1 AS calculated_iteration_num
    FROM {{ ref('int_gtfs_rt__vehicle_positions_trip_day_map_grouping') }}
    WHERE {{ incremental_where(default_start_var='PROD_GTFS_RT_START') }}
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
            ) AS ending_schedule_relationship
    FROM vehicle_positions
),

message_ids AS (
    {{ gtfs_rt_unnest_column_count_distinct(table = 'vehicle_positions',
    key_col = 'key',
    array_col = 'message_ids_array',
    output_column_name = 'num_distinct_message_ids') }}
),

header_timestamps AS (
    {{ gtfs_rt_unnest_column_count_distinct(table = 'vehicle_positions',
    key_col = 'key',
    array_col = 'header_timestamps_array',
    output_column_name = 'num_distinct_header_timestamps') }}
),

extract_ts AS (
    {{ gtfs_rt_unnest_column_count_distinct(table = 'vehicle_positions',
    key_col = 'key',
    array_col = 'extract_ts_array',
    output_column_name = 'num_distinct_extract_ts') }}
),

message_keys AS (
    {{ gtfs_rt_unnest_column_count_distinct(table = 'vehicle_positions',
    key_col = 'key',
    array_col = 'message_keys_array',
    output_column_name = 'num_distinct_message_keys') }}
),

vehicle_timestamps AS (
    {{ gtfs_rt_unnest_column_count_distinct(table = 'vehicle_positions',
    key_col = 'key',
    array_col = 'vehicle_timestamps_array',
    output_column_name = 'num_distinct_vehicle_timestamps') }}
),

aggregation AS(
     SELECT
        -- https://gtfs.org/realtime/reference/#message-tripdescriptor
        key,
        calculated_service_date,
        base64_url,
        trip_id,
        trip_start_time,
        calculated_iteration_num,
        trip_start_date,
        schedule_feed_timezone,
        schedule_base64_url,
        starting_schedule_relationship,
        ending_schedule_relationship,
        ARRAY_TO_STRING(ARRAY_AGG(DISTINCT trip_schedule_relationship ORDER BY trip_schedule_relationship), "|") AS trip_schedule_relationships, --noqa: L054
        ARRAY_TO_STRING(ARRAY_AGG(DISTINCT trip_route_id ORDER BY trip_route_id), "|") AS trip_route_ids, --noqa: L054
        ARRAY_TO_STRING(ARRAY_AGG(DISTINCT trip_direction_id ORDER BY trip_direction_id), "|") AS trip_direction_ids, --noqa: L054
        MIN(min_extract_ts) AS min_extract_ts,
        MAX(max_extract_ts) AS max_extract_ts,
        MIN(min_header_timestamp) AS min_header_timestamp,
        MAX(max_header_timestamp) AS max_header_timestamp,
        MIN(min_vehicle_timestamp) AS min_vehicle_timestamp,
        MAX(max_vehicle_timestamp) AS max_vehicle_timestamp,
    FROM window_functions
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 --noqa: L054
),

fct_vehicle_positions_trip_summaries AS (
    SELECT
        aggregation.key,
        {{ dbt_utils.generate_surrogate_key(['calculated_service_date', 'schedule_base64_url', 'trip_id', 'calculated_iteration_num']) }} AS trip_instance_key,
        calculated_service_date,
        base64_url,
        schedule_base64_url,
        trip_id,
        trip_start_time,
        calculated_iteration_num,
        trip_start_date,
        schedule_feed_timezone,
        starting_schedule_relationship,
        ending_schedule_relationship,
        {{ trim_make_empty_string_null('trip_route_ids') }} AS trip_route_ids,
        {{ trim_make_empty_string_null('trip_direction_ids') }} AS trip_direction_ids,
        {{ trim_make_empty_string_null('trip_schedule_relationships') }} AS trip_schedule_relationships,
        COALESCE(ARRAY_LENGTH(SPLIT(trip_route_ids, "|")), FALSE) > 1 AS warning_multiple_route_ids,
        COALESCE(ARRAY_LENGTH(SPLIT(trip_direction_ids, "|")), FALSE) > 1 AS warning_multiple_direction_ids,
        min_extract_ts,
        max_extract_ts,
        num_distinct_message_ids,
        num_distinct_header_timestamps,
        num_distinct_vehicle_timestamps,
        num_distinct_message_keys,
        num_distinct_extract_ts,
        TIMESTAMP_DIFF(max_extract_ts, min_extract_ts, MINUTE) AS extract_duration_minutes,
        DATETIME(min_extract_ts, "America/Los_Angeles") AS min_extract_datetime_pacific,
        DATETIME(max_extract_ts, "America/Los_Angeles") AS max_extract_datetime_pacific,
        DATETIME(min_extract_ts, schedule_feed_timezone) AS min_extract_datetime_local_tz,
        DATETIME(max_extract_ts, schedule_feed_timezone) AS max_extract_datetime_local_tz,
        min_header_timestamp,
        max_header_timestamp,
        TIMESTAMP_DIFF(max_header_timestamp, min_header_timestamp, MINUTE) AS header_duration_minutes,
        DATETIME(min_header_timestamp, "America/Los_Angeles") AS min_header_datetime_pacific,
        DATETIME(max_header_timestamp, "America/Los_Angeles") AS max_header_datetime_pacific,
        DATETIME(min_header_timestamp, schedule_feed_timezone) AS min_header_datetime_local_tz,
        DATETIME(max_header_timestamp, schedule_feed_timezone) AS max_header_datetime_local_tz,
        min_vehicle_timestamp,
        max_vehicle_timestamp,
        TIMESTAMP_DIFF(max_vehicle_timestamp, min_vehicle_timestamp, MINUTE) AS vehicle_duration_minutes,
        DATETIME(min_vehicle_timestamp, "America/Los_Angeles") AS min_vehicle_datetime_pacific,
        DATETIME(max_vehicle_timestamp, "America/Los_Angeles") AS max_vehicle_datetime_pacific,
        DATETIME(min_vehicle_timestamp, schedule_feed_timezone) AS min_vehicle_datetime_local_tz,
        DATETIME(max_vehicle_timestamp, schedule_feed_timezone) AS max_vehicle_datetime_local_tz,
    FROM aggregation
    LEFT JOIN message_ids USING (key)
    LEFT JOIN header_timestamps USING (key)
    LEFT JOIN extract_ts USING (key)
    LEFT JOIN message_keys USING (key)
    LEFT JOIN vehicle_timestamps USING (key)
)

SELECT * FROM fct_vehicle_positions_trip_summaries
