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
        AND tu._extract_ts BETWEEN urls_to_gtfs_datasets._valid_from AND urls_to_gtfs_datasets._valid_to
    LEFT JOIN dim_gtfs_datasets AS gd
        ON urls_to_gtfs_datasets.gtfs_dataset_key = gd.key
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
        _gtfs_dataset_name,

        TIMESTAMP_DIFF(_extract_ts, header_timestamp, SECOND) AS _header_message_age,
        TIMESTAMP_DIFF(_extract_ts, trip_update_timestamp, SECOND) AS _trip_update_message_age,
        TIMESTAMP_DIFF(header_timestamp, trip_update_timestamp, SECOND) AS _trip_update_message_age_vs_header,
        -- TODO: once #2457 merges, we should use the schedule feed timezone rather than just Pacific
        -- we need to get individual trip instances that can be merged with schedule feed trip instances
        COALESCE(
            PARSE_DATE("%Y%m%d",trip_start_date),
            DATE(trip_update_timestamp, "America/Los_Angeles"),
            DATE(header_timestamp, "America/Los_Angeles"),
            DATE(_extract_ts)) AS calculated_service_date_pacific,

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
