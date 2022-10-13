{{ config(materialized='table') }}

WITH dim_schedule_feeds AS (
    SELECT *
    FROM {{ ref('dim_schedule_feeds') }}
),

stg_gtfs_schedule__translations AS (
    SELECT *
    FROM {{ ref('stg_gtfs_schedule__translations') }}
),

make_dim AS (
{{ make_schedule_file_dimension_from_dim_schedule_feeds('dim_schedule_feeds', 'stg_gtfs_schedule__translations') }}
),

dim_translations AS (
    SELECT
        {{ dbt_utils.surrogate_key(['feed_key', 'table_name', 'field_name', 'language', 'record_id', 'record_sub_id', 'field_value']) }} AS key,
        feed_key,
        gtfs_dataset_key,
        table_name,
        field_name,
        language,
        translation,
        record_id,
        record_sub_id,
        field_value,
        base64_url,
        _valid_from,
        _valid_to
    FROM make_dim
)

SELECT * FROM dim_translations
