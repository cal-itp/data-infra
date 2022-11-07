WITH raw_validation_notices AS (
    SELECT * FROM {{ source('external_gtfs_schedule', 'validation_notices') }}
),

stg_gtfs_schedule__validation_notices AS (
    SELECT
        dt,
        base64_url,
        ts,
        metadata.gtfs_validator_version,
        metadata.extract_config.name AS name,
        metadata.extract_config.url AS url,
        metadata.extract_config.feed_type AS feed_type,
        metadata.extract_config.extracted_at AS _config_extract_ts,
        code,
        severity,
        totalNotices AS total_notices,
        sampleNotices AS sample_notices
    FROM raw_validation_notices
)

SELECT * FROM stg_gtfs_schedule__validation_notices
