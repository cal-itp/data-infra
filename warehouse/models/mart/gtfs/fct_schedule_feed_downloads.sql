{{ config(materialized='table') }}

WITH joined_feed_outcomes AS (
    SELECT *
    FROM {{ ref('int_gtfs_schedule__joined_feed_outcomes') }}
),

dim_schedule_feeds AS (
    SELECT *
    FROM {{ ref('dim_schedule_feeds') }}
),

fct_schedule_feeds AS (
    SELECT
        {{ dbt_utils.surrogate_key(['j.base64_url', 'j.ts']) }} as key,
        f.key AS feed_key,
        j.gtfs_dataset_key,
        j.ts,
        j.base64_url,
        j.download_success,
        j.download_exception,
        j.unzip_success,
        j.unzip_exception,
        j.zipfile_extract_md5hash,
        j.zipfile_files,
        j.zipfile_dirs,
        j.pct_files_successfully_parsed
    FROM joined_feed_outcomes AS j
    LEFT JOIN dim_schedule_feeds AS f
        ON j.base64_url = f.base64_url
        AND j.ts BETWEEN f._valid_from AND f._valid_to
)

SELECT * FROM fct_schedule_feeds
