WITH stg_gtfs_rt__service_alerts AS (
    SELECT *
    FROM {{ ref('stg_gtfs_rt__service_alerts') }}
),

keying AS (
    {{ gtfs_rt_messages_keying('stg_gtfs_rt__service_alerts') }}
),

fct_service_alerts_messages AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['_extract_ts', 'base64_url', 'id']) }} AS key,
        gtfs_dataset_key,
        dt,
        hour,
        base64_url,
        _extract_ts,
        _config_extract_ts,
        _gtfs_dataset_name,
        schedule_gtfs_dataset_key,
        schedule_base64_url,
        schedule_name,
        schedule_feed_key,
        schedule_feed_timezone,
        TIMESTAMP_DIFF(_extract_ts, header_timestamp, SECOND) AS _header_message_age,
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
