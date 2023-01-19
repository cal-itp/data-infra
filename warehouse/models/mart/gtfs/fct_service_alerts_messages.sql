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
        AND sa._extract_ts BETWEEN urls_to_gtfs_datasets._valid_from AND urls_to_gtfs_datasets._valid_to
    LEFT JOIN dim_gtfs_datasets AS gd
        ON urls_to_gtfs_datasets.gtfs_dataset_key = gd.key
),

fct_service_alerts_messages AS (
    SELECT
        {{ dbt_utils.surrogate_key(['_extract_ts', 'base64_url', 'id']) }} AS key,
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
        active_period,
        informed_entity,
        cause,
        effect,
        url,
        header_text,
        description_text,
        tts_header_text,
        tts_description_text,
        severity_level
    FROM keying
)

SELECT * FROM fct_service_alerts_messages
