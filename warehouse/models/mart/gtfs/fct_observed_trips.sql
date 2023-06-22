{{
    config(
        materialized='table',
    )
}}

WITH trip_updates AS (
    SELECT * FROM {{ ref('fct_trip_updates_summaries') }}
),

vehicle_positions AS (
    SELECT * FROM {{ ref('fct_vehicle_positions_trip_summaries') }}
),

service_alerts AS (
    SELECT * FROM {{ ref('fct_service_alerts_trip_summaries') }}
),

fct_observed_trips AS (
    SELECT
        -- keys/identifiers
        trip_instance_key,
        -- calculated service date, schedule URL, trip ID, and iteration num are the components of the key
        -- so for these we can coalesce
        COALESCE(
            tu.calculated_service_date,
            vp.calculated_service_date,
            sa.calculated_service_date
        ) AS calculated_service_date,
        COALESCE(
            tu.schedule_base64_url,
            vp.schedule_base64_url,
            sa.schedule_base64_url
        ) AS schedule_base64_url,
        COALESCE(tu.trip_id, vp.trip_id, sa.trip_id) AS trip_id,
        COALESCE(tu.calculated_iteration_num, vp.calculated_iteration_num, sa.calculated_iteration_num) AS calculated_iteration_num,

        COALESCE(tu.warning_multiple_route_ids, FALSE)
            OR COALESCE(vp.warning_multiple_route_ids, FALSE)
            OR COALESCE(sa.warning_multiple_route_ids, FALSE)
            OR COALESCE((tu.trip_route_ids != COALESCE(vp.trip_route_ids, tu.trip_route_ids)), FALSE)
            OR COALESCE((tu.trip_route_ids != COALESCE(sa.trip_route_ids, tu.trip_route_ids)), FALSE)
            OR COALESCE((vp.trip_route_ids != COALESCE(sa.trip_route_ids, vp.trip_route_ids)), FALSE) AS warning_multiple_route_ids,

        tu.warning_multiple_direction_ids
            OR COALESCE(vp.warning_multiple_direction_ids, FALSE)
            OR COALESCE(sa.warning_multiple_direction_ids, FALSE)
            OR COALESCE((tu.trip_direction_ids != COALESCE(vp.trip_direction_ids, tu.trip_direction_ids)), FALSE)
            OR COALESCE((tu.trip_direction_ids != COALESCE(sa.trip_direction_ids, tu.trip_direction_ids)), FALSE)
            OR COALESCE((vp.trip_direction_ids != COALESCE(sa.trip_direction_ids, vp.trip_direction_ids)), FALSE) AS warning_multiple_direction_ids,

        -- trip updates facts
        tu.trip_start_time AS tu_trip_start_time,
        tu.trip_start_date AS tu_trip_start_date,
        tu.warning_multiple_route_ids AS tu_warning_multiple_route_ids,
        tu.warning_multiple_direction_ids AS tu_warning_multiple_direction_ids,
        tu.starting_schedule_relationship AS tu_starting_schedule_relationship,
        tu.ending_schedule_relationship AS tu_ending_schedule_relationship,
        tu.trip_schedule_relationships AS tu_trip_schedule_relationships,
        tu.num_distinct_message_ids AS tu_num_distinct_message_ids,
        tu.min_extract_ts AS tu_min_extract_ts,
        tu.max_extract_ts AS tu_max_extract_ts,
        tu.num_distinct_extract_ts AS tu_num_distinct_extract_ts,
        tu.trip_route_ids AS tu_trip_route_ids,
        tu.trip_direction_ids AS tu_trip_direction_ids,
        tu.min_header_timestamp AS tu_min_header_timestamp,
        tu.max_header_timestamp AS tu_max_header_timestamp,
        tu.num_distinct_header_timestamps AS tu_num_distinct_header_timestamps,
        tu.min_trip_update_timestamp AS tu_min_trip_update_timestamp,
        tu.max_trip_update_timestamp AS tu_max_trip_update_timestamp,
        tu.num_distinct_trip_update_timestamps AS tu_num_distinct_trip_update_timestamps,
        tu.max_delay AS tu_max_delay,
        tu.num_distinct_skipped_stops AS tu_num_skipped_stops,
        tu.num_distinct_scheduled_stops
         + tu.num_distinct_canceled_stops
         + tu.num_distinct_added_stops AS tu_num_scheduled_canceled_added_stops,

        -- vehicle positions facts
        vp.trip_start_time AS vp_trip_start_time,
        vp.trip_start_date AS vp_trip_start_date,
        vp.warning_multiple_route_ids AS vp_warning_multiple_route_ids,
        vp.warning_multiple_direction_ids AS vp_warning_multiple_direction_ids,
        vp.starting_schedule_relationship AS vp_starting_schedule_relationship,
        vp.ending_schedule_relationship AS vp_ending_schedule_relationship,
        vp.trip_schedule_relationships AS vp_trip_schedule_relationships,
        vp.num_distinct_message_ids AS vp_num_distinct_message_ids,
        vp.min_extract_ts AS vp_min_extract_ts,
        vp.max_extract_ts AS vp_max_extract_ts,
        vp.num_distinct_extract_ts AS vp_num_distinct_extract_ts,
        vp.trip_route_ids AS vp_trip_route_ids,
        vp.trip_direction_ids AS vp_trip_direction_ids,
        vp.min_header_timestamp AS vp_min_header_timestamp,
        vp.max_header_timestamp AS vp_max_header_timestamp,
        vp.num_distinct_header_timestamps AS vp_num_distinct_header_timestamps,
        vp.min_vehicle_timestamp AS vp_min_vehicle_timestamp,
        vp.max_vehicle_timestamp AS vp_max_vehicle_timestamp,
        vp.num_distinct_vehicle_timestamps AS vp_num_distinct_vehicle_timestamps,
        {# vp.first_position_latitude AS vp_first_position_latitude,
        vp.first_position_longitude AS vp_first_position_longitude,
        vp.last_position_latitude AS vp_last_position_latitude,
        vp.last_position_longitude AS vp_last_position_longitude, #}

        -- service alerts facts
        sa.trip_start_time AS sa_trip_start_time,
        sa.trip_start_date AS sa_trip_start_date,
        sa.warning_multiple_route_ids AS sa_warning_multiple_route_ids,
        sa.warning_multiple_direction_ids AS sa_warning_multiple_direction_ids,
        sa.starting_schedule_relationship AS sa_starting_schedule_relationship,
        sa.ending_schedule_relationship AS sa_ending_schedule_relationship,
        sa.trip_schedule_relationships AS sa_trip_schedule_relationships,
        sa.num_distinct_message_ids AS sa_num_distinct_message_ids,
        sa.min_extract_ts AS sa_min_extract_ts,
        sa.max_extract_ts AS sa_max_extract_ts,
        sa.num_distinct_extract_ts AS sa_num_distinct_extract_ts,
        sa.trip_route_ids AS sa_trip_route_ids,
        sa.trip_direction_ids AS sa_trip_direction_ids,
        sa.min_header_timestamp AS sa_min_header_timestamp,
        sa.max_header_timestamp AS sa_max_header_timestamp,
        sa.num_distinct_header_timestamps AS sa_num_distinct_header_timestamps,
        sa.alert_content_array AS sa_alert_content_array,

        -- keying
        tu.base64_url AS tu_base64_url,
        vp.base64_url AS vp_base64_url,
        sa.base64_url AS sa_base64_url,

    FROM trip_updates AS tu
    FULL OUTER JOIN vehicle_positions AS vp
        USING (trip_instance_key)
    FULL OUTER JOIN service_alerts AS sa
        USING (trip_instance_key)
)

SELECT * FROM fct_observed_trips
