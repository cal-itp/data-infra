{{ config(materialized='table') }}

WITH joined_feed_outcomes AS (
    SELECT *
    FROM {{ ref('int_gtfs_schedule__joined_feed_outcomes') }}
),

dim_gtfs_datasets AS (
    SELECT *
    FROM {{ ref('dim_gtfs_datasets') }}
),

keying AS (
    SELECT
        gd.key as gtfs_dataset_key,
        f.*
    FROM joined_feed_outcomes AS f
    -- TODO: this can lead to fanout until we de-dupe on the dim_gtfs_datasets side
    -- currently no enforcement that URL is unique
    LEFT JOIN dim_gtfs_datasets AS gd
        ON f.base64_url = gd.base64_url
        AND f._config_extract_ts BETWEEN gd._valid_from AND gd._valid_to
),

fct_schedule_feeds AS (
    SELECT
        {{ dbt_utils.surrogate_key(['base64_url', 'ts', 'gtfs_dataset_key']) }} as key,
        gtfs_dataset_key,
        ts,
        base64_url,
        download_success,
        download_exception,
        unzip_success,
        unzip_exception,
        zipfile_extract_md5hash,
        zipfile_files,
        zipfile_dirs,
        pct_files_successfully_parsed
    FROM keying
)


SELECT * FROM fct_schedule_feeds
