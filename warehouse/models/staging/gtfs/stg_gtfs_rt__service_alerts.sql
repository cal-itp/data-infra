WITH external_service_alerts AS (
    SELECT *
    FROM {{ source('external_gtfs_rt', 'service_alerts') }}
),

stg_gtfs_rt__service_alerts AS (
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

        alert.activePeriod.`start` AS active_period_start,
        alert.activePeriod.`end` AS active_period_end,

        alert.informedEntity.agency_id AS informed_entity_agency_id,
        alert.informedEntity.route_id AS informed_entity_route_id,
        alert.informedEntity.routeType AS informed_entity_route_type,
        alert.informedEntity.directionId AS informed_entity_direction_id,

        alert.informedEntity.trip.tripId AS informed_entity_trip_id,
        alert.informedEntity.trip.routeId AS informed_entity_trip_route_id,
        alert.informedEntity.trip.directionId AS informed_entity_trip_direction_id,
        alert.informedEntity.trip.startTime AS informed_entity_trip_start_time,
        alert.informedEntity.trip.startDate AS informed_entity_trip_start_date,
        alert.informedEntity.trip.scheduleRelationship AS informed_entity_trip_schedule_relationship,

        alert.informedEntity.stopId AS informed_entity_stop_id,

        alert.cause AS cause,
        alert.effect AS effect,

        alert.url.translation.text AS url_translation_text,
        alert.url.translation.language AS url_translation_language,

        alert.header_text.translation.text AS header_text_translation_text,
        alert.header_text.translation.language AS header_text_translation_language,

        alert.description_text.translation.text AS description_text_translation_text,
        alert.description_text.translation.language AS description_text_translation_language,

        alert.tts_header_text.translation.text AS tts_header_text_translation_text,
        alert.tts_header_text.translation.language AS tts_header_text_translation_language,

        alert.tts_description_text.translation.text AS tts_description_text_translation_text,
        alert.tts_description_text.translation.language AS tts_description_text_translation_language,

        alert.serverityLevel AS severity_level

    FROM external_service_alerts
)

SELECT * FROM stg_gtfs_rt__service_alerts
