{{ config(materialized='table') }}

WITH urls AS (
    SELECT *
    FROM {{ source('external_gtfs_schedule', 'download_outcomes') }}
),

zipfiles AS (
    SELECT
        * EXCEPT(zipfile_extract_path, zipfile_files, zipfile_dirs),
        CAST(FROM_BASE64(
            REPLACE(REPLACE(REGEXP_EXTRACT(zipfile_extract_path, r'base64_url=([^/]+)'), '-', '+'), '_', '/')
            ) AS STRING) AS url,
        CAST(REGEXP_EXTRACT(zipfile_extract_path, r'ts=([^/]+)') AS TIMESTAMP) AS ts
    FROM {{ source('external_gtfs_schedule', 'unzip_outcomes') }}
),

stg_gtfs_schedule__feed_outcomes AS (
    SELECT
        urls.ts AS download_ts,
        urls.success AS download_success,
        urls.exception AS download_exception,
        urls.extract.response_code AS download_response_code,
        urls.input_record.uri AS airtable_uri,
        urls.input_record.pipeline_url AS airtable_pipeline_uri,
        zipfiles.ts AS unzip_ts,
        zipfiles.success AS unzip_success,
        zipfiles.exception AS unzip_exception,
        zipfiles.url AS download_url
    FROM urls
    FULL OUTER JOIN zipfiles
        ON COALESCE(urls.input_record.pipeline_url, urls.input_record.uri) = zipfiles.url
            AND urls.ts = zipfiles.ts
)

-- stg_feeds AS (
--     SELECT
--         url,
--         ts,
--         zipfile_extract_md5hash,
--         success,
--         FIRST_VALUE(ts)
--         OVER (PARTITION BY url, zipfile_extract_md5hash, success ORDER BY ts
--             ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
--         AS first_extract,
--         LAST_VALUE(ts)
--         OVER (PARTITION BY url, zipfile_extract_md5hash, success ORDER BY ts
--             ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
--         AS latest_extract,
--         DENSE_RANK() OVER (ORDER BY ts DESC) = 1 AS in_latest
--     FROM zipfiles
-- )

SELECT * FROM stg_gtfs_schedule__feed_outcomes
