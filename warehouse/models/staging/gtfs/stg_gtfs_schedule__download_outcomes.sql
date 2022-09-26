WITH raw_download_outcomes AS (
    SELECT
        *,
        {{ to_url_safe_base64('config.url') }} AS base64_url
    FROM {{ source('external_gtfs_schedule', 'download_outcomes') }}
),

stg_gtfs_schedule__download_outcomes AS (
    SELECT
        dt,
        {{ farm_surrogate_key(['base64_url', 'ts']) }} as key,
        config.name AS name,
        config.url AS url,
        config.feed_type AS feed_type,
        config.extracted_at AS config_extracted_at,
        config.schedule_url_for_validation AS schedule_url_for_validation,
        success AS download_success,
        exception AS download_exception,
        extract.response_code AS download_response_code,
        extract.response_headers AS download_response_headers,
        base64_url,
        ts AS ts
    FROM raw_download_outcomes
)

SELECT * FROM stg_gtfs_schedule__download_outcomes
