{{ config(materialized='table') }}

WITH stg_gtfs_schedule__file_parse_outcomes AS (
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
        {{ dbt_utils.surrogate_key([
            'parse.ts',
            'parse.base64_url',
            'parse.original_filename']) }} as key,
        feeds.key AS feed_key,
        parse.gtfs_filename,
        parse.parse_success,
        parse.parse_exception,
        parse.ts,
        parse.base64_url,
        {{ from_url_safe_base64('parse.base64_url') }} AS string_url,
        datasets.key AS gtfs_dataset_key,
        datasets.name AS gtfs_dataset_name
    FROM stg_gtfs_schedule__file_parse_outcomes AS parse
    LEFT JOIN urls_to_gtfs_datasets AS urls
        ON parse.base64_url = urls.base64_url
    LEFT JOIN dim_schedule_feeds AS feeds
        ON parse.base64_url = feeds.base64_url
        AND parse.ts BETWEEN feeds._valid_from AND feeds._valid_to
    LEFT JOIN dim_gtfs_datasets AS datasets
        ON urls.base64_url = datasets.base64_url
)

SELECT * FROM fct_schedule_files_parsed
