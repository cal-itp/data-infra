WITH raw_validation_outcomes AS (
    SELECT
        *,
        {{ to_url_safe_base64('`extract`.config.url') }} AS base64_url
    -- TODO: make me validation_outcomes
    FROM {{ source('external_gtfs_schedule', 'validations_outcomes') }}
),

stg_gtfs_schedule__validation_outcomes AS (
    SELECT
        dt,
        `extract`.config.name AS name,
        `extract`.config.url AS url,
        `extract`.config.feed_type AS feed_type,
        `extract`.config.extracted_at AS _config_extract_ts,
        success AS validation_success,
        exception AS validation_exception,
        validation.filename AS validation_filename,
        validation.system_errors AS validation_system_errors,
        base64_url,
        `extract`.ts AS ts
    FROM raw_validation_outcomes
)

SELECT * FROM stg_gtfs_schedule__validation_outcomes
