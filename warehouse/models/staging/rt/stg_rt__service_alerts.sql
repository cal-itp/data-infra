WITH source AS (
    SELECT * FROM {{ source('gtfs_rt_external_tables', 'service_alerts') }}
),

stg_rt__service_alerts AS (
    SELECT
        metadata.itp_id AS calitp_itp_id,
        metadata.url AS calitp_url_number,
        metadata.path AS original_file_path,
        dt AS date,

        id,

        alert.activePeriod as active_periods,
        alert.informedEntity as informed_entities,
        alert.cause as cause,
        alert.effect as effect,
        alert.url.translation as url_translations,
        alert.header_text.translation as header_text_translations,
        alert.description_text.translation as description_text_translations,
        alert.tts_header_text.translation as tts_header_text_translations,
        alert.tts_description_text.translation as tts_description_text_translations,
        alert.severityLevel as severity_level,


        {{ dbt_utils.surrogate_key(['metadata.path',
                                    'id']) }} AS key

    FROM source
)

SELECT * FROM stg_rt__service_alerts
