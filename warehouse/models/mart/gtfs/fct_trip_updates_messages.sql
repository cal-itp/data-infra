WITH stg_gtfs_rt__trip_updates AS (
    SELECT *
    FROM {{ ref('stg_gtfs_rt__trip_updates') }}
),

keying AS (
    {{ gtfs_rt_messages_keying('stg_gtfs_rt__trip_updates') }}
),

fct_trip_updates_messages AS (
    SELECT
        -- TODO: this is not unique yet
        {{ dbt_utils.generate_surrogate_key(['base64_url', '_extract_ts', 'id', 'vehicle_id', 'trip_id']) }} as key,
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

        TIMESTAMP_DIFF(_extract_ts, header_timestamp, SECOND) AS _header_message_age,
        TIMESTAMP_DIFF(_extract_ts, trip_update_timestamp, SECOND) AS _trip_update_message_age,
        TIMESTAMP_DIFF(header_timestamp, trip_update_timestamp, SECOND) AS _trip_update_message_age_vs_header,

        header_timestamp,
        header_version,
        header_incrementality,

        id,

        trip_update_timestamp,
        trip_update_delay,

        vehicle_id,
        vehicle_label,
        vehicle_license_plate,

        trip_id,
        trip_route_id,
        trip_direction_id,
        trip_start_time,
        trip_start_date,
        trip_schedule_relationship,

        stop_time_updates,
    FROM keying
)


SELECT * FROM fct_trip_updates_messages
