{{ config(materialized='table') }}

WITH download_outcomes AS (
    SELECT
        *,
        {{ to_url_safe_base64('`extract`.config.url') }} as base64_url
    FROM {{ source('external_gtfs_schedule', 'download_outcomes') }}
),

unzip_outcomes AS (
    SELECT *,
        {{ to_url_safe_base64('`extract`.config.url') }} as base64_url
    FROM {{ source('external_gtfs_schedule', 'unzip_outcomes') }}
),

stg_gtfs_schedule__feed_outcomes AS (
    SELECT
        download_outcomes.dt AS download_dt,
        download_outcomes.ts AS download_ts,
        download_outcomes.success AS download_success,
        download_outcomes.exception AS download_exception,
        download_outcomes.extract.response_code AS download_response_code,
        download_outcomes.extract.config.url AS download_url,
        download_outcomes.base64_url AS download_base64_url,
        unzip_outcomes.dt AS unzip_dt,
        unzip_outcomes.extract.ts AS unzip_ts,
        unzip_outcomes.success AS unzip_success,
        unzip_outcomes.exception AS unzip_exception,
        unzip_outcomes.base64_url AS unzip_base64_url
    FROM download_outcomes
    FULL OUTER JOIN unzip_outcomes
        ON download_outcomes.base64_url = unzip_outcomes.base64_url
        AND download_outcomes.ts = unzip_outcomes.extract.ts
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
