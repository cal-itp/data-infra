WITH raw_unzip_outcomes AS (
    SELECT
        *,
        {{ to_url_safe_base64('config.url') }} AS base64_url
    FROM {{ source('external_gtfs_schedule', 'unzip_outcomes') }}
),

stg_gtfs_schedule__unzip_outcomes AS (
    SELECT
        dt,
        config.name AS name,
        config.url AS url,
        config.feed_type AS feed_type,
        config.extracted_at AS config_extracted_at,
        success AS unzip_success,
        exception AS unzip_exception,
        unzip_outcomes.zipfile_extract_md5hash,
        unzip_outcomes.zipfile_files,
        unzip_outcomes.zipfile_dirs,
        base64_url,
        ts AS ts
    FROM raw_unzip_outcomes
)

SELECT * FROM stg_gtfs_schedule__unzip_outcomes
