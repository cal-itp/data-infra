WITH stg_gtfs_rt__vehicle_positions AS (
    SELECT *
    FROM {{ ref('stg_gtfs_rt__vehicle_positions') }}
),

keying AS (
    {{ gtfs_rt_messages_keying('stg_gtfs_rt__vehicle_positions') }}
),

fct_vehicle_positions_messages AS (
    SELECT
        -- ideally this would not include vehicle_id / trip_id, but using it for now because
        -- MTC 511 regional feed does not have feed-unique entity ids
        {{ dbt_utils.generate_surrogate_key(['base64_url', '_extract_ts', 'id', 'position_latitude', 'position_longitude']) }} as key,
        gtfs_dataset_key,
        dt,
        hour,
        base64_url,
        _extract_ts,
        _config_extract_ts,
        name,
        schedule_gtfs_dataset_key,
        schedule_base64_url,
        schedule_name,
        schedule_feed_key,
        schedule_feed_timezone,
        COALESCE(
            trip_start_date,
            DATE(header_timestamp, schedule_feed_timezone),
            DATE(_extract_ts, schedule_feed_timezone)) AS service_date,

        TIMESTAMP_DIFF(_extract_ts, header_timestamp, SECOND) AS _header_message_age,
        TIMESTAMP_DIFF(_extract_ts, vehicle_timestamp, SECOND) AS _vehicle_message_age,
        TIMESTAMP_DIFF(header_timestamp, vehicle_timestamp, SECOND) AS _vehicle_message_age_vs_header,


        header_timestamp,
        header_version,
        header_incrementality,

        id,

        current_stop_sequence,
        stop_id,
        current_status,
        vehicle_timestamp,
        congestion_level,
        occupancy_status,
        occupancy_percentage,

        vehicle_id,
        vehicle_label,
        vehicle_license_plate,
        vehicle_wheelchair_accessible,

        trip_id,
        trip_route_id,
        trip_direction_id,
        trip_start_time,
        trip_start_time_interval,
        trip_start_date,
        trip_schedule_relationship,

        position_latitude,
        position_longitude,
        position_bearing,
        position_odometer,
        position_speed
    FROM keying
)


SELECT * FROM fct_vehicle_positions_messages
