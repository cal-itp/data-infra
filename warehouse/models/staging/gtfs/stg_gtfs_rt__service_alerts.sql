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

        unnested_active_period.start AS active_period_start,
        unnested_active_period.end AS active_period_end,

        unnested_informed_entity.agencyId AS informed_entity_agency_id,
        unnested_informed_entity.routeId AS informed_entity_route_id,
        unnested_informed_entity.routeType AS informed_entity_route_type,
        unnested_informed_entity.directionId AS informed_entity_direction_id,
        unnested_informed_entity.trip.tripId AS informed_entity_trip_id,
        unnested_informed_entity.trip.routeId AS informed_entity_trip_route_id,
        unnested_informed_entity.trip.directionId AS informed_entity_trip_direction_id,
        unnested_informed_entity.trip.startTime AS informed_entity_trip_start_time,
        unnested_informed_entity.trip.startDate AS informed_entity_trip_start_date,
        unnested_informed_entity.trip.scheduleRelationship AS informed_entity_trip_schedule_relationship,
        unnested_informed_entity.stopId AS informed_entity_stop_id,

        alert.cause AS cause,
        alert.effect AS effect,

        unnested_url_translation.text AS url_text,
        unnested_url_translation.text AS url_language,

        unnested_header_text_translation.text AS header_text_text,
        unnested_header_text_translation.text AS header_text_language,

        unnested_description_text_translation.text AS description_text_text,
        unnested_description_text_translation.text AS description_text_language,

        unnested_tts_header_text_translation.text AS tts_header_text_text,
        unnested_tts_header_text_translation.text AS tts_header_text_language,

        unnested_tts_description_text_translation.text AS tts_description_text_text,
        unnested_tts_description_text_translation.text AS tts_description_text_language,

        alert.severityLevel AS severity_level
    FROM external_service_alerts
    -- https://stackoverflow.com/questions/44918108/google-bigquery-i-lost-null-row-when-using-unnest-function
    -- these arrays have nulls
    LEFT JOIN UNNEST(external_service_alerts.alert.activePeriod) AS unnested_active_period
    LEFT JOIN UNNEST(external_service_alerts.alert.informedEntity) AS unnested_informed_entity
    LEFT JOIN UNNEST(external_service_alerts.alert.url.translation) AS unnested_url_translation
    LEFT JOIN UNNEST(external_service_alerts.alert.header_text.translation) AS unnested_header_text_translation
    LEFT JOIN UNNEST(external_service_alerts.alert.description_text.translation) AS unnested_description_text_translation
    LEFT JOIN UNNEST(external_service_alerts.alert.tts_header_text.translation) AS unnested_tts_header_text_translation
    LEFT JOIN UNNEST(external_service_alerts.alert.tts_description_text.translation) AS unnested_tts_description_text_translation
)

SELECT * FROM stg_gtfs_rt__service_alerts
