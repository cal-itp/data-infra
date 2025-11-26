WITH raw_unzip_outcomes AS (
    SELECT
        *,
        {{ to_url_safe_base64('`extract`.config.url') }} AS base64_url
    FROM {{ source('external_gtfs_schedule', 'unzip_outcomes') }}
),

stg_gtfs_schedule__unzip_outcomes AS (
    SELECT DISTINCT
        dt,
        `extract`.config.name AS name,
        `extract`.config.url AS url,
        `extract`.config.feed_type AS feed_type,
        `extract`.config.extracted_at AS _config_extract_ts,
        success AS unzip_success,
        exception AS unzip_exception,
        zipfile_extract_md5hash,
        zipfile_files,
        zipfile_dirs,
        base64_url,
        `extract`.ts AS ts
    FROM raw_unzip_outcomes
)

SELECT * FROM stg_gtfs_schedule__unzip_outcomes
