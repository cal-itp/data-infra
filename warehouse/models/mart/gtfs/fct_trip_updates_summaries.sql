{{
    config(
        materialized='table',
        cluster_by='base64_url',
    )
}}

WITH trip_updates_grouped AS (
    SELECT * EXCEPT(trip_direction_id),
        CAST(trip_direction_id AS STRING) AS trip_direction_id,
        -- subtract one because row_number is 1-based count and in frequency-based schedule we use 0-based
        DENSE_RANK() OVER (PARTITION BY
            base64_url,
            calculated_service_date,
            trip_id
            ORDER BY trip_start_time) - 1 AS calculated_iteration_num
    FROM {{ ref('int_gtfs_rt__trip_updates_trip_day_map_grouping') }}
    -- Torrance has two sets of RT feeds that reference the same schedule feed
    -- this causes problems because trips across both feeds then resolve to the same `trip_instance_key`
    -- so we manually drop the non-customer-facing feed
    WHERE base64_url != 'aHR0cDovL3d3dy5teWJ1c2luZm8uY29tL2d0ZnNydC90cmlwcw=='
),

window_functions AS (
    SELECT *,
        FIRST_VALUE(trip_schedule_relationship)
            OVER (
                PARTITION BY key
                ORDER BY min_trip_update_timestamp
                ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
            ) AS starting_schedule_relationship,
        LAST_VALUE(trip_schedule_relationship)
            OVER (
                PARTITION BY key
                ORDER BY max_trip_update_timestamp
                ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
            ) AS ending_schedule_relationship
    FROM trip_updates_grouped
),

message_ids AS (
    {{ gtfs_rt_unnest_column_count_distinct(table = 'trip_updates_grouped',
    key_col = 'key',
    array_col = 'message_ids_array',
    output_column_name = 'num_distinct_message_ids') }}
),

header_timestamps AS (
    {{ gtfs_rt_unnest_column_count_distinct(table = 'trip_updates_grouped',
    key_col = 'key',
    array_col = 'header_timestamps_array',
    output_column_name = 'num_distinct_header_timestamps') }}
),

trip_update_timestamps AS (
    {{ gtfs_rt_unnest_column_count_distinct(table = 'trip_updates_grouped',
    key_col = 'key',
    array_col = 'trip_update_timestamps_array',
    output_column_name = 'num_distinct_trip_update_timestamps') }}
),

extract_ts AS (
    {{ gtfs_rt_unnest_column_count_distinct(table = 'trip_updates_grouped',
    key_col = 'key',
    array_col = 'extract_ts_array',
    output_column_name = 'num_distinct_extract_ts') }}
),

message_keys AS (
    {{ gtfs_rt_unnest_column_count_distinct(table = 'trip_updates_grouped',
    key_col = 'key',
    array_col = 'message_keys_array',
    output_column_name = 'num_distinct_message_keys') }}
),

skipped_stops AS (
    {{ gtfs_rt_unnest_column_count_distinct(table = 'trip_updates_grouped',
    key_col = 'key',
    array_col = 'skipped_stops_array',
    output_column_name = 'num_distinct_skipped_stops') }}
),

added_stops AS (
    {{ gtfs_rt_unnest_column_count_distinct(table = 'trip_updates_grouped',
    key_col = 'key',
    array_col = 'added_stops_array',
    output_column_name = 'num_distinct_added_stops') }}
),

scheduled_stops AS (
    {{ gtfs_rt_unnest_column_count_distinct(table = 'trip_updates_grouped',
    key_col = 'key',
    array_col = 'scheduled_stops_array',
    output_column_name = 'num_distinct_scheduled_stops') }}
),

canceled_stops AS (
    {{ gtfs_rt_unnest_column_count_distinct(table = 'trip_updates_grouped',
    key_col = 'key',
    array_col = 'canceled_stops_array',
    output_column_name = 'num_distinct_canceled_stops') }}
),

--TODO: add pipe delimited strings for distinct routes, directions, trip schedule relationships; use plural names
aggregation AS(
     SELECT
        -- https://gtfs.org/realtime/reference/#message-tripdescriptor
        key,
        calculated_service_date,
        base64_url,
        trip_id,
        trip_start_time,
        schedule_feed_timezone,
        schedule_base64_url,
        calculated_iteration_num,
        starting_schedule_relationship,
        ending_schedule_relationship,
        trip_start_time_interval,
        MIN(trip_start_date) AS trip_start_date,
        ARRAY_TO_STRING(ARRAY_AGG(DISTINCT trip_schedule_relationship ORDER BY trip_schedule_relationship), "|") AS trip_schedule_relationships,
        ARRAY_TO_STRING(ARRAY_AGG(DISTINCT trip_route_id ORDER BY trip_route_id), "|") AS trip_route_ids,
        ARRAY_TO_STRING(ARRAY_AGG(DISTINCT trip_direction_id ORDER BY trip_direction_id), "|") AS trip_direction_ids,
        MIN(min_extract_ts) AS min_extract_ts,
        MAX(max_extract_ts) AS max_extract_ts,
        MIN(min_header_timestamp) AS min_header_timestamp,
        MAX(max_header_timestamp) AS max_header_timestamp,
        MIN(min_trip_update_timestamp) AS min_trip_update_timestamp,
        MAX(max_trip_update_timestamp) AS max_trip_update_timestamp,
        MAX(max_delay) AS max_delay,
    FROM window_functions
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 --noqa: L054
),

fct_trip_updates_summaries AS (
    SELECT
        -- https://gtfs.org/realtime/reference/#message-tripdescriptor
        aggregation.key,
        {{ dbt_utils.generate_surrogate_key(['calculated_service_date', 'schedule_base64_url', 'trip_id', 'calculated_iteration_num']) }} AS trip_instance_key,
        calculated_service_date,
        base64_url,
        schedule_base64_url,
        trip_id,
        trip_start_time,
        trip_start_time_interval,
        calculated_iteration_num,
        trip_start_date,
        starting_schedule_relationship,
        ending_schedule_relationship,
        {{ trim_make_empty_string_null('trip_route_ids') }} AS trip_route_ids,
        {{ trim_make_empty_string_null('trip_direction_ids') }} AS trip_direction_ids,
        {{ trim_make_empty_string_null('trip_schedule_relationships') }} AS trip_schedule_relationships,
        COALESCE(ARRAY_LENGTH(SPLIT(trip_route_ids, "|")) > 1, FALSE) AS warning_multiple_route_ids,
        COALESCE(ARRAY_LENGTH(SPLIT(trip_direction_ids, "|")) > 1, FALSE) AS warning_multiple_direction_ids,
        schedule_feed_timezone,
        num_distinct_message_ids,
        num_distinct_header_timestamps,
        num_distinct_trip_update_timestamps,
        num_distinct_message_keys,
        num_distinct_extract_ts,
        min_extract_ts,
        max_extract_ts,
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
        min_trip_update_timestamp,
        max_trip_update_timestamp,
        TIMESTAMP_DIFF(max_trip_update_timestamp, min_trip_update_timestamp, MINUTE) AS trip_update_duration_minutes,
        DATETIME(min_trip_update_timestamp, "America/Los_Angeles") AS min_trip_update_datetime_pacific,
        DATETIME(max_trip_update_timestamp, "America/Los_Angeles") AS max_trip_update_datetime_pacific,
        DATETIME(min_trip_update_timestamp, schedule_feed_timezone) AS min_trip_update_datetime_local_tz,
        DATETIME(max_trip_update_timestamp, schedule_feed_timezone) AS max_trip_update_datetime_local_tz,
        max_delay,
        num_distinct_skipped_stops,
        num_distinct_scheduled_stops,
        num_distinct_added_stops,
        num_distinct_canceled_stops,
    FROM aggregation
    LEFT JOIN message_ids USING (key)
    LEFT JOIN header_timestamps USING (key)
    LEFT JOIN extract_ts USING (key)
    LEFT JOIN message_keys USING (key)
    LEFT JOIN trip_update_timestamps USING (key)
    LEFT JOIN skipped_stops USING (key)
    LEFT JOIN scheduled_stops USING (key)
    LEFT JOIN added_stops USING (key)
    LEFT JOIN canceled_stops USING (key)
)

SELECT * FROM fct_trip_updates_summaries
