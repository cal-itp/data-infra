WITH stg_gtfs_rt__vehicle_positions AS (
    SELECT *
    FROM {{ ref('stg_gtfs_rt__vehicle_positions') }}
),

dim_gtfs_datasets AS (
    SELECT *
    FROM {{ ref('dim_gtfs_datasets') }}
),

keying AS (
    SELECT
        gd.key as gtfs_dataset_key,
        vp.*
    FROM stg_gtfs_rt__vehicle_positions AS vp
    LEFT JOIN dim_gtfs_datasets AS gd
        ON vp.base64_url = gd.base64_url
        AND vp._config_extract_ts BETWEEN gd._valid_from AND gd._valid_to
),

fct_vehicle_positions_messages AS (
    SELECT
        -- ideally this would not include vehicle_id / trip_id, but using it for now because
        -- MTC 511 regional feed does not have feed-unique entity ids
        {{ dbt_utils.surrogate_key(['base64_url', '_extract_ts', 'id', 'position_latitude', 'position_longitude']) }} as key,
        gtfs_dataset_key,
        dt,
        hour,
        base64_url,
        _extract_ts,
        _config_extract_ts,
        _name,

        header_timestamp,
        header_version
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

        trip_id,
        trip_route_id,
        trip_direction_id,
        trip_start_time,
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
