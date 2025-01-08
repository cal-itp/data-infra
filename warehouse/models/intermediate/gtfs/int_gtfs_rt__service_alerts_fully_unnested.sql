WITH messages AS (
    SELECT *
    FROM {{ ref('fct_service_alerts_messages') }}
),

int_gtfs_rt__service_alerts_fully_unnested AS (
    SELECT
        key AS service_alert_message_key,
        gtfs_dataset_key,
        dt,
        hour,
        base64_url,
        _extract_ts,
        _config_extract_ts,
        gtfs_dataset_name,
        schedule_gtfs_dataset_key,
        schedule_base64_url,
        schedule_name,
        schedule_feed_key,
        schedule_feed_timezone,

        _header_message_age,
        header_version,
        header_incrementality,
        header_timestamp,
        id,

        cause,
        effect,

        -- active periods, converting from STRINGS since some agency has bad data that insn't unnestable as INTs
        SAFE_CAST(unnested_active_period.start AS INT) AS active_period_start,
        SAFE_CAST(unnested_active_period.end AS INT) AS active_period_end,

        -- informted entities
        unnested_informed_entity.agencyId AS agency_id,
        unnested_informed_entity.routeId AS route_id,
        unnested_informed_entity.routeType AS route_type,
        unnested_informed_entity.directionId AS direction_id,
        unnested_informed_entity.trip.tripId AS trip_id,
        unnested_informed_entity.trip.routeId AS trip_route_id,
        unnested_informed_entity.trip.directionId AS trip_direction_id,
        unnested_informed_entity.trip.startTime AS trip_start_time,
        {{ gtfs_time_string_to_interval('unnested_informed_entity.trip.startTime') }} AS trip_start_time_interval,
        PARSE_DATE("%Y%m%d", unnested_informed_entity.trip.startDate) AS trip_start_date,
        unnested_informed_entity.trip.scheduleRelationship AS trip_schedule_relationship,
        unnested_informed_entity.stopId AS stop_id,

        -- text (translations)
        unnested_header_text_translation.text AS header_text_text,
        unnested_header_text_translation.language AS header_text_language,

        unnested_description_text_translation.text AS description_text_text,
        unnested_description_text_translation.language AS description_text_language,

        unnested_tts_header_text_translation.text AS tts_header_text_text,
        unnested_tts_header_text_translation.language AS tts_header_text_language,

        unnested_tts_description_text_translation.text AS tts_description_text_text,
        unnested_tts_description_text_translation.language AS tts_description_text_language,

        unnested_url_translation.text AS url_text,
        unnested_url_translation.language AS url_language,

        -- try to assess which rows are English versions (if available);
        -- we don't want to double count alerts when multiple lanugages are present
        CASE
            WHEN unnested_header_text_translation.language LIKE "%en%" THEN 100
            WHEN unnested_header_text_translation.language IS NULL THEN 1
            ELSE 0
        END AS english_likelihood
    FROM messages
    LEFT JOIN UNNEST(messages.informed_entity) AS unnested_informed_entity
    LEFT JOIN UNNEST(messages.active_period) AS unnested_active_period
    -- https://stackoverflow.com/questions/44918108/google-bigquery-i-lost-null-row-when-using-unnest-function
    -- these arrays may have nulls
    LEFT JOIN UNNEST(messages.header_text.translation) AS unnested_header_text_translation
    LEFT JOIN UNNEST(messages.description_text.translation) AS unnested_description_text_translation
    LEFT JOIN UNNEST(messages.tts_header_text.translation) AS unnested_tts_header_text_translation
    LEFT JOIN UNNEST(messages.tts_description_text.translation) AS unnested_tts_description_text_translation
    LEFT JOIN UNNEST(messages.url.translation) AS unnested_url_translation
    -- filter where languages match, otherwise we get cartesian product of language combinations
    WHERE COALESCE(unnested_description_text_translation.language, unnested_header_text_translation.language, 'language') = COALESCE(unnested_header_text_translation.language, 'language')
       AND COALESCE(unnested_tts_header_text_translation.language, unnested_header_text_translation.language, 'language') = COALESCE(unnested_header_text_translation.language, 'language')
       AND COALESCE(unnested_tts_description_text_translation.language, unnested_header_text_translation.language, 'language') = COALESCE(unnested_header_text_translation.language, 'language')
       AND COALESCE(unnested_url_translation.language, unnested_header_text_translation.language, 'language') = COALESCE(unnested_header_text_translation.language, 'language')
)

SELECT * FROM int_gtfs_rt__service_alerts_fully_unnested
