{{ config(materialized='table') }}

WITH dim_schedule_feeds AS (
    SELECT *
    FROM {{ ref('dim_schedule_feeds') }}
),

stg_gtfs_schedule__pathways AS (
    SELECT *
    FROM {{ ref('stg_gtfs_schedule__pathways') }}
),

make_dim AS (
{{ make_schedule_file_dimension_from_dim_schedule_feeds('dim_schedule_feeds', 'stg_gtfs_schedule__pathways') }}
),

dim_pathways AS (
    SELECT
        {{ dbt_utils.surrogate_key(['feed_key', 'pathway_id']) }} AS key,
        feed_key,
        gtfs_dataset_key,
        pathway_id,
        from_stop_id,
        to_stop_id,
        pathway_mode,
        is_bidirectional,
        length,
        traversal_time,
        stair_count,
        max_slope,
        min_width,
        signposted_as,
        reversed_signposted_as,
        base64_url,
        _valid_from,
        _valid_to
    FROM make_dim
)

SELECT * FROM dim_pathways
