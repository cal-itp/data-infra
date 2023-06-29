{{
    config(
        materialized='table',
        cluster_by='base64_url',
    )
}}

WITH vehicle_positions AS ( --noqa: ST03
    SELECT * FROM {{ ref('int_gtfs_rt__vehicle_positions_trip_day_map_grouping') }}
),

vehicle_positions_no_lat_long AS ( --noqa: ST03
    SELECT * EXCEPT (first_position_latitude, first_position_longitude, last_position_latitude, last_position_longitude)
    FROM vehicle_positions
),

base_fct AS (
    {{ gtfs_rt_trip_summaries(input_table = 'vehicle_positions_no_lat_long',
    urls_to_drop = '("aHR0cDovL3d3dy5teWJ1c2luZm8uY29tL2d0ZnNydC92ZWhpY2xlcw==")',
    extra_timestamp = 'vehicle')
    }}
),

lat_long AS (
    -- can also qualify but the point is that you will get two rows for trips that cross UTC date boundary
    SELECT DISTINCT
        key,
        FIRST_VALUE(first_position_latitude)
            OVER
            (PARTITION BY key
            ORDER BY COALESCE(min_vehicle_timestamp, min_header_timestamp, min_extract_ts)
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
            ) AS first_position_latitude,
        FIRST_VALUE(first_position_longitude)
            OVER
            (PARTITION BY key
            ORDER BY COALESCE(min_vehicle_timestamp, min_header_timestamp, min_extract_ts)
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
            ) AS first_position_longitude,
        LAST_VALUE(last_position_latitude)
            OVER
            (PARTITION BY key
            ORDER BY COALESCE(max_vehicle_timestamp, max_header_timestamp, max_extract_ts)
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
            ) AS last_position_latitude,
        LAST_VALUE(last_position_longitude)
            OVER
            (PARTITION BY key
            ORDER BY COALESCE(max_vehicle_timestamp, max_header_timestamp, max_extract_ts)
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
            ) AS last_position_longitude
    FROM vehicle_positions
),

fct_vehicle_positions_trip_summaries AS (
    SELECT
        base_fct.key,
        trip_instance_key,
        calculated_service_date,
        base64_url,
        schedule_base64_url,
        trip_id,
        trip_start_time,
        trip_start_time_interval,
        calculated_iteration_num,
        trip_start_date,
        schedule_feed_timezone,
        starting_schedule_relationship,
        ending_schedule_relationship,
        first_position_latitude,
        first_position_longitude,
        last_position_latitude,
        last_position_longitude,
        trip_route_ids,
        trip_direction_ids,
        trip_schedule_relationships,
        warning_multiple_route_ids,
        warning_multiple_direction_ids,
        min_extract_ts,
        max_extract_ts,
        num_distinct_message_ids,
        num_distinct_header_timestamps,
        num_distinct_vehicle_timestamps,
        num_distinct_message_keys,
        num_distinct_extract_ts,
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
        min_vehicle_timestamp,
        max_vehicle_timestamp,
        vehicle_duration_minutes,
        min_vehicle_datetime_pacific,
        max_vehicle_datetime_pacific,
        min_vehicle_datetime_local_tz,
        max_vehicle_datetime_local_tz,
    FROM base_fct
    LEFT JOIN lat_long USING (key)
)

SELECT * FROM fct_vehicle_positions_trip_summaries
