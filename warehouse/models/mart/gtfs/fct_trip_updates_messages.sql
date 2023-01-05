WITH stg_gtfs_rt__trip_updates AS (
    SELECT *
    FROM {{ ref('stg_gtfs_rt__trip_updates') }}
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
        tu.*
    FROM stg_gtfs_rt__trip_updates AS tu
    LEFT JOIN urls_to_gtfs_datasets
        ON tu.base64_url = urls_to_gtfs_datasets.base64_url
    LEFT JOIN dim_gtfs_datasets AS gd
        ON urls_to_gtfs_datasets.gtfs_dataset_key = gd.key
),

fct_trip_updates_messages AS (
    SELECT
        {{ dbt_utils.surrogate_key(['base64_url', '_extract_ts', 'id']) }} as key,
        gtfs_dataset_key,
        dt,
        hour,
        base64_url,
        _extract_ts,
        _config_extract_ts,
        _gtfs_dataset_name,

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
