{{
    config(
        materialized='incremental',
        incremental_strategy='insert_overwrite',
        partition_by = {
            'field': 'service_date',
            'data_type': 'date',
            'granularity': 'day',
        },
        cluster_by='base64_url',
        on_schema_change='append_new_columns'
    )
}}

WITH trip_updates AS( --noqa: ST03
    SELECT *
    FROM {{ ref('int_gtfs_rt__trip_updates_trip_day_map_grouping') }}
    WHERE dt >= "2024-01-1" AND dt <= '2024-01-31'
),

 base_fct AS (
    {{ gtfs_rt_trip_summaries(
        input_table = 'trip_updates',
        urls_to_drop = '("aHR0cDovL3d3dy5teWJ1c2luZm8uY29tL2d0ZnNydC90cmlwcw==")',
        extra_timestamp = 'trip_update',
        extra_summarized = {'max_delay': 'MAX(max_delay)'}
    ) }}
 ),

skipped_stops AS (
    {{ gtfs_rt_unnest_column_count_distinct(table = 'trip_updates',
    key_col = 'key',
    array_col = 'skipped_stops_array',
    output_column_name = 'num_distinct_skipped_stops') }}
),

added_stops AS (
    {{ gtfs_rt_unnest_column_count_distinct(table = 'trip_updates',
    key_col = 'key',
    array_col = 'added_stops_array',
    output_column_name = 'num_distinct_added_stops') }}
),

scheduled_stops AS (
    {{ gtfs_rt_unnest_column_count_distinct(table = 'trip_updates',
    key_col = 'key',
    array_col = 'scheduled_stops_array',
    output_column_name = 'num_distinct_scheduled_stops') }}
),

canceled_stops AS (
    {{ gtfs_rt_unnest_column_count_distinct(table = 'trip_updates',
    key_col = 'key',
    array_col = 'canceled_stops_array',
    output_column_name = 'num_distinct_canceled_stops') }}
),

fct_trip_updates_summaries AS (
    SELECT
        -- https://gtfs.org/realtime/reference/#message-tripdescriptor
        base_fct.key,
        trip_instance_key,
        service_date,
        base64_url,
        schedule_base64_url,
        trip_id,
        trip_start_time,
        trip_start_time_interval,
        iteration_num,
        trip_start_date,
        starting_schedule_relationship,
        ending_schedule_relationship,
        trip_route_ids,
        trip_direction_ids,
        trip_schedule_relationships,
        warning_multiple_route_ids,
        warning_multiple_direction_ids,
        schedule_feed_timezone,
        num_distinct_message_ids,
        num_distinct_header_timestamps,
        num_distinct_trip_update_timestamps,
        num_distinct_message_keys,
        num_distinct_extract_ts,
        COALESCE(min_trip_update_timestamp, min_header_timestamp, min_extract_ts) AS min_ts,
        COALESCE(min_trip_update_datetime_pacific, min_header_datetime_pacific, min_extract_datetime_pacific) AS min_datetime_pacific,
        COALESCE(max_trip_update_timestamp, max_header_timestamp, max_extract_ts) AS max_ts,
        COALESCE(max_trip_update_datetime_pacific, max_header_datetime_pacific, max_extract_datetime_pacific) AS max_datetime_pacific,
        COALESCE(num_distinct_trip_update_timestamps, num_distinct_header_timestamps) AS num_distinct_updates,
        min_extract_ts,
        max_extract_ts,
        extract_duration_minutes,
        min_extract_datetime_pacific,
        max_extract_datetime_pacific,
        min_extract_datetime_local_tz,
        max_extract_datetime_local_tz,
        min_header_timestamp,
        max_header_timestamp,
        header_duration_minutes,
        min_header_datetime_pacific,
        max_header_datetime_pacific,
        min_header_datetime_local_tz,
        max_header_datetime_local_tz,
        min_trip_update_timestamp,
        max_trip_update_timestamp,
        trip_update_duration_minutes,
        min_trip_update_datetime_pacific,
        max_trip_update_datetime_pacific,
        min_trip_update_datetime_local_tz,
        max_trip_update_datetime_local_tz,
        max_delay,
        num_distinct_skipped_stops,
        num_distinct_scheduled_stops,
        num_distinct_added_stops,
        num_distinct_canceled_stops,
    FROM base_fct
    LEFT JOIN skipped_stops USING (key)
    LEFT JOIN scheduled_stops USING (key)
    LEFT JOIN added_stops USING (key)
    LEFT JOIN canceled_stops USING (key)
)

SELECT * FROM fct_trip_updates_summaries
