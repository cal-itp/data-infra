WITH stg_gtfs_rt__vehicle_positions AS (
    SELECT *
    FROM {{ ref('stg_gtfs_rt__vehicle_positions') }}
),

urls_to_gtfs_datasets AS (
    SELECT * FROM {{ ref('int_transit_database__urls_to_gtfs_datasets') }}
),

dim_gtfs_datasets AS (
    SELECT *
    FROM {{ ref('dim_gtfs_datasets') }}
),

keying AS (
    SELECT
        urls_to_gtfs_datasets.gtfs_dataset_key,
        gd.name as _gtfs_dataset_name,
        vp.*
    FROM stg_gtfs_rt__vehicle_positions AS vp
    LEFT JOIN urls_to_gtfs_datasets
        ON vp.base64_url = urls_to_gtfs_datasets.base64_url
        AND vp._extract_ts BETWEEN urls_to_gtfs_datasets._valid_from AND urls_to_gtfs_datasets._valid_to
    LEFT JOIN dim_gtfs_datasets AS gd
        ON urls_to_gtfs_datasets.gtfs_dataset_key = gd.key
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
        _gtfs_dataset_name,

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
