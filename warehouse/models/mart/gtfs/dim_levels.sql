{{ config(materialized='table') }}

WITH dim_schedule_feeds AS (
    SELECT *
    FROM {{ ref('dim_schedule_feeds') }}
),

stg_gtfs_schedule__levels AS (
    SELECT *
    FROM {{ ref('stg_gtfs_schedule__levels') }}
),

make_dim AS (
{{ make_schedule_file_dimension_from_dim_schedule_feeds('dim_schedule_feeds', 'stg_gtfs_schedule__levels') }}
),

dim_levels AS (
    SELECT
        {{ dbt_utils.surrogate_key(['feed_key', 'level_id']) }} AS key,
        feed_key,
        level_id,
        level_index,
        level_name,
        base64_url,
        _valid_from,
        _valid_to,
        _is_current
    FROM make_dim
)

SELECT * FROM dim_levels
