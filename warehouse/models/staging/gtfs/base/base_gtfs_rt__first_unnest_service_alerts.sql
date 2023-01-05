WITH external_service_alerts AS (
    SELECT *
    FROM {{ source('external_gtfs_rt', 'service_alerts') }}
),

first_unnest AS (
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

        alert.headerText AS header_text,
        alert.descriptionText AS description_text,
        alert.ttsHeaderText AS tts_header_text,
        alert.ttsDescriptionText AS tts_description_text,
        alert.url AS url,

        alert.severityLevel AS severity_level
    FROM external_service_alerts
    -- https://stackoverflow.com/questions/44918108/google-bigquery-i-lost-null-row-when-using-unnest-function
    -- these arrays have nulls
    LEFT JOIN UNNEST(external_service_alerts.alert.activePeriod) AS unnested_active_period
    LEFT JOIN UNNEST(external_service_alerts.alert.informedEntity) AS unnested_informed_entity
),

base_gtfs_rt__first_unnest_service_alerts AS (
    SELECT

        {{ dbt_utils.surrogate_key(['base64_url',
            '_extract_ts',
            'id',
            'informed_entity_agency_id',
            'informed_entity_route_id',
            'informed_entity_trip_id',
            'informed_entity_trip_start_time',
            'informed_entity_trip_start_date',
            'informed_entity_stop_id']) }} as msg_key,

        dt,
        hour,
        base64_url,

        _extract_ts,
        _config_extract_ts,
        _name,

        header_timestamp,
        header_incrementality,
        header_version,

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

        header_text,
        description_text,
        tts_header_text,
        tts_description_text,
        url,

        severity_level
    FROM first_unnest
)

SELECT * FROM base_gtfs_rt__first_unnest_service_alerts
