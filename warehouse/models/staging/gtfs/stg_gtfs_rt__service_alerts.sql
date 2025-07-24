{{ config(materialized='table') }}

WITH stg_gtfs_rt__service_alerts AS (
    SELECT
        dt,
        hour,
        base64_url,

        metadata.extract_ts AS _extract_ts,
        metadata.extract_config.extracted_at AS _config_extract_ts,
        metadata.extract_config.name AS _name,

        TIMESTAMP_SECONDS(header.timestamp) AS header_timestamp,
        header.incrementality AS header_incrementality,
        header.gtfsRealtimeVersion AS header_version,

        id,

        alert.activePeriod AS active_period,
        alert.informedEntity AS informed_entity,

        alert.cause AS cause,
        alert.effect AS effect,

        alert.headerText AS header_text,
        alert.descriptionText AS description_text,
        alert.ttsHeaderText AS tts_header_text,
        alert.ttsDescriptionText AS tts_description_text,
        alert.url AS url,

        alert.severityLevel AS severity_level

    FROM {{ source('external_gtfs_rt', 'service_alerts') }}
    WHERE dt >= DATE_SUB(CURRENT_DATE(), INTERVAL 6 MONTH) -- last 6 months
)

SELECT * FROM stg_gtfs_rt__service_alerts
