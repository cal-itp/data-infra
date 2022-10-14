{{ config(materialized='table') }}

WITH dim_schedule_feeds AS (
    SELECT *
    FROM {{ ref('dim_schedule_feeds') }}
),

stg_gtfs_schedule__shapes AS (
    SELECT *
    FROM {{ ref('stg_gtfs_schedule__shapes') }}
),

make_dim AS (
{{ make_schedule_file_dimension_from_dim_schedule_feeds('dim_schedule_feeds', 'stg_gtfs_schedule__shapes') }}
),

dim_shapes AS (
    SELECT
        {{ dbt_utils.surrogate_key(['feed_key', 'shape_id', 'shape_pt_sequence']) }} AS key,
        feed_key,
        gtfs_dataset_key,
        shape_id,
        shape_pt_lat,
        shape_pt_lon,
        shape_pt_sequence,
        shape_dist_traveled,
        base64_url,
        _valid_from,
        _valid_to
    FROM make_dim
)

SELECT * FROM dim_shapes
