{{ config(materialized='table') }}

WITH zipfiles AS (
    SELECT
        * EXCEPT(zipfile_extract_path, zipfile_files, zipfile_dirs),
        CAST(FROM_BASE64(
            REPLACE(REPLACE(REGEXP_EXTRACT(zipfile_extract_path, r'base64_url=([^/]+)'), '-', '+'), '_', '/')
            ) AS STRING) AS url,
        REGEXP_EXTRACT(zipfile_extract_path, r'ts=([^/]+)') AS ts
    FROM {{ source('external_gtfs_schedule', 'unzip_outcomes') }}
),

stg_feeds AS (
    SELECT
        url,
        ts,
        zipfile_extract_md5hash,
        success,
        FIRST_VALUE(ts)
        OVER (PARTITION BY url, zipfile_extract_md5hash, success ORDER BY ts
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
        AS first_extract,
        LAST_VALUE(ts)
        OVER (PARTITION BY url, zipfile_extract_md5hash, success ORDER BY ts
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
        AS latest_extract,
        DENSE_RANK() OVER (ORDER BY ts DESC) = 1 AS in_latest
    FROM zipfiles
)

SELECT * FROM stg_feeds
