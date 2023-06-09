{{
    config(
        materialized='table',
        cluster_by='base64_url',
    )
}}

WITH trip_updates_grouped AS (
    SELECT
        *,
        -- https://gtfs.org/realtime/reference/#message-tripdescriptor
        {{ dbt_utils.generate_surrogate_key([
            'calculated_service_date',
            'base64_url',
            'trip_id',
            'trip_start_time',
        ]) }} as key,
    FROM {{ ref('int_gtfs_rt__trip_updates_trip_day_map_grouping') }}
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
        ) AS ending_schedule_relationship,
    FIRST_VALUE(trip_route_id)
        OVER (
            PARTITION BY key
            ORDER BY min_trip_update_timestamp
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS starting_route_id,
    LAST_VALUE(trip_route_id)
        OVER (
            PARTITION BY key
            ORDER BY max_trip_update_timestamp
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS ending_route_id,
    FIRST_VALUE(trip_direction_id)
        OVER (
            PARTITION BY key
            ORDER BY min_trip_update_timestamp
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS starting_direction_id,
    LAST_VALUE(trip_direction_id)
        OVER (
            PARTITION BY key
            ORDER BY max_trip_update_timestamp
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS ending_direction_id,
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

non_array_agg AS(
     SELECT
        -- https://gtfs.org/realtime/reference/#message-tripdescriptor
        key,
        calculated_service_date,
        base64_url,
        trip_id,
        trip_start_time,
        trip_start_date,
        feed_timezone,
        starting_schedule_relationship,
        ending_schedule_relationship,
        starting_route_id,
        ending_route_id,
        starting_direction_id,
        ending_direction_id,
        MIN(min_extract_ts) AS min_extract_ts,
        MAX(max_extract_ts) AS max_extract_ts,
        MIN(min_header_timestamp) AS min_header_timestamp,
        MAX(max_header_timestamp) AS max_header_timestamp,
        MIN(min_trip_update_timestamp) AS min_trip_update_timestamp,
        MAX(max_trip_update_timestamp) AS max_trip_update_timestamp,
        MAX(max_delay) AS max_delay,
    FROM window_functions
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13
),

fct_trip_updates_summaries AS (
    SELECT
        -- https://gtfs.org/realtime/reference/#message-tripdescriptor
        non_array_agg.key,
        calculated_service_date,
        base64_url,
        trip_id,
        trip_start_time,
        trip_start_date,
        starting_schedule_relationship,
        ending_schedule_relationship,
        starting_route_id,
        ending_route_id,
        feed_timezone,
        num_distinct_message_ids,
        num_distinct_header_timestamps,
        num_distinct_trip_update_timestamps,
        num_distinct_message_keys,
        num_distinct_extract_ts,
        min_extract_ts,
        max_extract_ts,
        min_header_timestamp,
        max_header_timestamp,
        min_trip_update_timestamp,
        max_trip_update_timestamp,
        max_delay,
        num_distinct_skipped_stops,
        num_distinct_scheduled_stops,
        num_distinct_added_stops,
        num_distinct_canceled_stops,
    FROM non_array_agg
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
