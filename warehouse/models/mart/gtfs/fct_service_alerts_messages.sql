WITH stg_gtfs_rt__service_alerts AS (
    SELECT *
    FROM {{ ref('stg_gtfs_rt__service_alerts') }}
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
        sa.*
    FROM stg_gtfs_rt__service_alerts AS sa
    LEFT JOIN urls_to_gtfs_datasets
        ON sa.base64_url = urls_to_gtfs_datasets.base64_url
    LEFT JOIN dim_gtfs_datasets AS gd
        ON urls_to_gtfs_datasets.gtfs_dataset_key = gd.key
),

fct_service_alerts_messages AS (
    SELECT
        -- same message id when unnested can appear multiple times for each informed entity
        {{ dbt_utils.surrogate_key(['base64_url',
            '_extract_ts',
            'id',
            'informed_entity_agency_id',
            'informed_entity_route_id',
            'informed_entity_trip_id',
            'informed_entity_trip_start_time',
            'informed_entity_trip_start_date',
            'informed_entity_stop_id']) }} as key,
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
        active_period_start,
        active_period_end,
        informed_entity_agency_id,
        informed_entity_route_id,
        informed_entity_route_type,
        informed_entity_direction_id,
        informed_entity_trip_id,
        informed_entity_trip_route_id,
        informed_entity_trip_direction_id,
        informed_entity_trip_start_time,
        informed_entity_trip_start_date,
        informed_entity_trip_schedule_relationship,
        informed_entity_stop_id,
        cause,
        effect,
        url_text,
        url_language,
        header_text_text,
        header_text_language,
        description_text_text,
        description_text_language,
        tts_header_text_text,
        tts_header_text_language,
        tts_description_text_text,
        tts_description_text_language,
        severity_level
    FROM keying
)


SELECT * FROM fct_service_alerts_messages
