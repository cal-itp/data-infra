{{ config(materialized='table') }}

WITH download_outcomes AS (
    SELECT
        *,
        {{ to_url_safe_base64('config.url') }} as base64_url
    FROM {{ source('external_gtfs_schedule', 'download_outcomes') }}
),

unzip_outcomes AS (
    SELECT *,
        {{ to_url_safe_base64('`extract`.config.url') }} as base64_url
    FROM {{ source('external_gtfs_schedule', 'unzip_outcomes') }}
),

stg_gtfs_schedule__feed_outcomes AS (
    SELECT
        download_outcomes.dt AS dt,
        {{ farm_surrogate_key(['download_outcomes.base64_url', 'download_outcomes.ts']) }} as key,
        download_outcomes.config.name AS name,
        download_outcomes.config.url AS url,
        download_outcomes.config.feed_type AS feed_type,
        download_outcomes.config.extracted_at AS config_extracted_at,
        download_outcomes.config.schedule_url_for_validation AS schedule_url_for_validation,
        download_outcomes.success AS download_success,
        download_outcomes.exception AS download_exception,
        download_outcomes.extract.response_code AS download_response_code,
        download_outcomes.extract.response_headers AS download_response_headers,
        unzip_outcomes.success AS unzip_success,
        unzip_outcomes.exception AS unzip_exception,
        unzip_outcomes.zipfile_extract_md5hash,
        unzip_outcomes.zipfile_files,
        unzip_outcomes.zipfile_dirs,
        download_outcomes.base64_url AS base64_url,
        download_outcomes.ts AS ts
    FROM download_outcomes
    LEFT JOIN unzip_outcomes
        ON download_outcomes.base64_url = unzip_outcomes.base64_url
        AND download_outcomes.ts = unzip_outcomes.extract.ts
)

SELECT * FROM stg_gtfs_schedule__feed_outcomes
