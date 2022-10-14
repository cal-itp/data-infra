{{ config(materialized='table') }}

WITH dim_schedule_feeds AS (
    SELECT *
    FROM {{ ref('dim_schedule_feeds') }}
),

stg_gtfs_schedule__areas AS (
    SELECT *
    FROM {{ ref('stg_gtfs_schedule__areas') }}
),

make_dim AS (
{{ make_schedule_file_dimension_from_dim_schedule_feeds('dim_schedule_feeds', 'stg_gtfs_schedule__areas') }}
),

dim_areas AS (
    SELECT
        {{ dbt_utils.surrogate_key(['feed_key', 'area_id']) }} AS key,
        feed_key,

        area_id,
        area_name,
        base64_url,
        _valid_from,
        _valid_to
    FROM make_dim
)

SELECT * FROM dim_areas
