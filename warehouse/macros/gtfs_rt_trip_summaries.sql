{% macro gtfs_rt_trip_summaries(
    input_table,
    urls_to_drop,
    extra_summarized = None,
    extra_timestamp = None) %}


WITH add_cols AS (
    SELECT * EXCEPT(trip_direction_id),
        CAST(trip_direction_id AS STRING) AS trip_direction_id,
        -- subtract one because row_number is 1-based count and in frequency-based schedule we use 0-based
        DENSE_RANK() OVER (PARTITION BY
            base64_url,
            service_date,
            trip_id
            ORDER BY trip_start_time) - 1 AS iteration_num
    FROM {{ input_table }}
    -- Torrance has two sets of RT feeds that reference the same schedule feed
    -- this causes problems because trips across both feeds then resolve to the same `trip_instance_key`
    -- so we manually drop the non-customer-facing feed
    WHERE base64_url NOT IN {{ urls_to_drop }}
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
    FROM add_cols
),

message_ids AS (
    {{ gtfs_rt_unnest_column_count_distinct(table = 'add_cols',
    key_col = 'key',
    array_col = 'message_ids_array',
    output_column_name = 'num_distinct_message_ids') }}
),

header_timestamps AS (
    {{ gtfs_rt_unnest_column_count_distinct(table = 'add_cols',
    key_col = 'key',
    array_col = 'header_timestamps_array',
    output_column_name = 'num_distinct_header_timestamps') }}
),

{% if extra_timestamp %}
{{ extra_timestamp }}_timestamps AS (
    {{ gtfs_rt_unnest_column_count_distinct(table = 'add_cols',
    key_col = 'key',
    array_col = extra_timestamp + '_timestamps_array',
    output_column_name = 'num_distinct_' + extra_timestamp + '_timestamps') }}
),
{% endif %}

extract_ts AS (
    {{ gtfs_rt_unnest_column_count_distinct(table = 'add_cols',
    key_col = 'key',
    array_col = 'extract_ts_array',
    output_column_name = 'num_distinct_extract_ts') }}
),

message_keys AS (
    {{ gtfs_rt_unnest_column_count_distinct(table = 'add_cols',
    key_col = 'key',
    array_col = 'message_keys_array',
    output_column_name = 'num_distinct_message_keys') }}
),

aggregation AS(
     SELECT
        -- https://gtfs.org/realtime/reference/#message-tripdescriptor
        key,
        service_date,
        base64_url,
        trip_id,
        trip_start_time,
        iteration_num,
        schedule_feed_timezone,
        schedule_base64_url,
        starting_schedule_relationship,
        ending_schedule_relationship,
        trip_start_time_interval,
        MIN(trip_start_date) AS trip_start_date,
        ARRAY_TO_STRING(ARRAY_AGG(DISTINCT trip_schedule_relationship ORDER BY trip_schedule_relationship), "|") AS trip_schedule_relationships, --noqa: L054
        ARRAY_TO_STRING(ARRAY_AGG(DISTINCT trip_route_id ORDER BY trip_route_id), "|") AS trip_route_ids, --noqa: L054
        ARRAY_TO_STRING(ARRAY_AGG(DISTINCT trip_direction_id ORDER BY trip_direction_id), "|") AS trip_direction_ids, --noqa: L054
        MIN(min_extract_ts) AS min_extract_ts,
        MAX(max_extract_ts) AS max_extract_ts,
        MIN(min_header_timestamp) AS min_header_timestamp,
        MAX(max_header_timestamp) AS max_header_timestamp,
        {% if extra_summarized %}
            {% for k, v in extra_summarized.items() %}
            {{ v }} AS {{ k }},
            {% endfor %}
        {% endif %}
        {% if extra_timestamp %}
        MIN(min_{{ extra_timestamp }}_timestamp) AS min_{{ extra_timestamp }}_timestamp,
        MAX(max_{{ extra_timestamp }}_timestamp) AS max_{{ extra_timestamp }}_timestamp
        {% endif %}
    FROM window_functions
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11
)


SELECT
    aggregation.key,
    {{ dbt_utils.generate_surrogate_key(['service_date', 'schedule_base64_url', 'trip_id', 'iteration_num']) }} AS trip_instance_key,
    service_date,
    base64_url,
    trip_id,
    trip_start_time,
    trip_start_time_interval,
    iteration_num,
    trip_start_date,
    schedule_feed_timezone,
    schedule_base64_url,
    starting_schedule_relationship,
    ending_schedule_relationship,
    {{ trim_make_empty_string_null('trip_route_ids') }} AS trip_route_ids,
    {{ trim_make_empty_string_null('trip_direction_ids') }} AS trip_direction_ids,
    {{ trim_make_empty_string_null('trip_schedule_relationships') }} AS trip_schedule_relationships,
    COALESCE(ARRAY_LENGTH(SPLIT(trip_route_ids, "|")) > 1, FALSE) AS warning_multiple_route_ids,
    COALESCE(ARRAY_LENGTH(SPLIT(trip_direction_ids, "|")) > 1, FALSE) AS warning_multiple_direction_ids,
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
    {% if extra_timestamp %}
    min_{{ extra_timestamp }}_timestamp,
    max_{{ extra_timestamp }}_timestamp,
    TIMESTAMP_DIFF(max_{{ extra_timestamp }}_timestamp, min_{{ extra_timestamp }}_timestamp, MINUTE) AS {{ extra_timestamp }}_duration_minutes,
    DATETIME(min_{{ extra_timestamp }}_timestamp, "America/Los_Angeles") AS min_{{ extra_timestamp }}_datetime_pacific,
    DATETIME(max_{{ extra_timestamp }}_timestamp, "America/Los_Angeles") AS max_{{ extra_timestamp }}_datetime_pacific,
    DATETIME(min_{{ extra_timestamp }}_timestamp, schedule_feed_timezone) AS min_{{ extra_timestamp }}_datetime_local_tz,
    DATETIME(max_{{ extra_timestamp }}_timestamp, schedule_feed_timezone) AS max_{{ extra_timestamp }}_datetime_local_tz,
    num_distinct_{{ extra_timestamp }}_timestamps,
    {% endif %}
    {% if extra_summarized %}
        {% for k, v in extra_summarized.items() %}
        {{ k }},
        {% endfor %}
    {% endif %}
    num_distinct_message_ids,
    num_distinct_header_timestamps,
    num_distinct_message_keys,
    num_distinct_extract_ts
FROM aggregation
LEFT JOIN message_ids USING (key)
LEFT JOIN header_timestamps USING (key)
LEFT JOIN extract_ts USING (key)
LEFT JOIN message_keys USING (key)
{% if extra_timestamp %}
LEFT JOIN {{ extra_timestamp }}_timestamps USING(key)
{% endif %}

{% endmacro %}
