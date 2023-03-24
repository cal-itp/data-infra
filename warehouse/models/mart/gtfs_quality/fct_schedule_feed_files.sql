{{ config(materialized='table') }}

WITH file_unzip_outcomes AS (
    SELECT
        * EXCEPT(zipfile_files)
    FROM {{ ref('stg_gtfs_schedule__unzip_outcomes') }}
    CROSS JOIN UNNEST(zipfile_files) AS feed_file
    WHERE feed_file IS NOT NULL
),

stg_gtfs_schedule__file_parse_outcomes AS (
    SELECT *
    FROM {{ ref('stg_gtfs_schedule__file_parse_outcomes') }}
),

dim_schedule_feeds AS (
    SELECT *
    FROM {{ ref('dim_schedule_feeds') }}
),

urls_to_gtfs_datasets AS (
    SELECT *
    FROM {{ ref('int_transit_database__urls_to_gtfs_datasets') }}
),

dim_gtfs_datasets AS (
    SELECT *
    FROM {{ ref('dim_gtfs_datasets') }}
),

fct_schedule_files_parsed AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key([
            'unzip.ts',
            'unzip.base64_url',
            'unzip.feed_file']) }} as key,
        feeds.key AS feed_key,
        unzip.feed_file AS original_filepath,
        -- these can have directories etc. at the beginning
        SPLIT(unzip.feed_file, "/")[ORDINAL(ARRAY_LENGTH(SPLIT(unzip.feed_file, "/")))] AS original_filename,
        parse.gtfs_filename,
        unzip.ts,
        unzip.base64_url,
        unzip.unzip_success,
        unzip.unzip_exception,
        parse_success,
        parse_exception,
        {{ from_url_safe_base64('unzip.base64_url') }} AS string_url,
        datasets.key AS gtfs_dataset_key,
        datasets.name AS gtfs_dataset_name
    FROM file_unzip_outcomes AS unzip
    LEFT JOIN stg_gtfs_schedule__file_parse_outcomes AS parse
        ON unzip.feed_file = parse.original_filename
        AND unzip.ts = parse.ts
        AND unzip.base64_url = parse.base64_url
    LEFT JOIN urls_to_gtfs_datasets AS urls
        ON unzip.base64_url = urls.base64_url
        AND unzip.ts BETWEEN urls._valid_from AND urls._valid_to
    LEFT JOIN dim_schedule_feeds AS feeds
        ON unzip.base64_url = feeds.base64_url
        AND unzip.ts BETWEEN feeds._valid_from AND feeds._valid_to
    LEFT JOIN dim_gtfs_datasets AS datasets
        ON urls.gtfs_dataset_key = datasets.key
)

SELECT * FROM fct_schedule_files_parsed
