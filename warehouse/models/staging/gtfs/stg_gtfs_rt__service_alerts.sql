WITH base_gtfs_rt__first_unnest_service_alerts AS (
    SELECT *
    FROM {{ ref('base_gtfs_rt__first_unnest_service_alerts') }}
),

stg_gtfs_rt__service_alerts AS (
    SELECT
        msg_key,
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

        unnested_url_translation.text AS url_text,
        unnested_url_translation.language AS url_language,

        unnested_header_text_translation.text AS header_text_text,
        unnested_header_text_translation.language AS header_text_language,

        unnested_description_text_translation.text AS description_text_text,
        unnested_description_text_translation.language AS description_text_language,

        unnested_tts_header_text_translation.text AS tts_header_text_text,
        unnested_tts_header_text_translation.language AS tts_header_text_language,

        unnested_tts_description_text_translation.text AS tts_description_text_text,
        unnested_tts_description_text_translation.language AS tts_description_text_language,

        severity_level
    FROM base_gtfs_rt__first_unnest_service_alerts
    -- https://stackoverflow.com/questions/44918108/google-bigquery-i-lost-null-row-when-using-unnest-function
    -- these arrays have nulls
    LEFT JOIN UNNEST(base_gtfs_rt__first_unnest_service_alerts.header_text.translation) AS unnested_header_text_translation
    LEFT JOIN UNNEST(base_gtfs_rt__first_unnest_service_alerts.description_text.translation) AS unnested_description_text_translation
    LEFT JOIN UNNEST(base_gtfs_rt__first_unnest_service_alerts.tts_header_text.translation) AS unnested_tts_header_text_translation
    LEFT JOIN UNNEST(base_gtfs_rt__first_unnest_service_alerts.tts_description_text.translation) AS unnested_tts_description_text_translation
    LEFT JOIN UNNEST(base_gtfs_rt__first_unnest_service_alerts.url.translation) AS unnested_url_translation
    -- filter where languages match, otherwise we get cartesian product of language combinations
    WHERE COALESCE(unnested_description_text_translation.language, unnested_header_text_translation.language, 'language') = COALESCE(unnested_header_text_translation.language, 'language')
       AND COALESCE(unnested_tts_header_text_translation.language, unnested_header_text_translation.language, 'language') = COALESCE(unnested_header_text_translation.language, 'language')
       AND COALESCE(unnested_tts_description_text_translation.language, unnested_header_text_translation.language, 'language') = COALESCE(unnested_header_text_translation.language, 'language')
       AND COALESCE(unnested_url_translation.language, unnested_header_text_translation.language, 'language') = COALESCE(unnested_header_text_translation.language, 'language')
)

SELECT * FROM stg_gtfs_rt__service_alerts
