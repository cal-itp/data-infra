{{ config(materialized='ephemeral') }}

WITH int_gtfs_quality__rt_feed_guideline_index AS (
    SELECT * FROM {{ ref('int_gtfs_quality__rt_feed_guideline_index') }}
),

int_gtfs_quality__rt_feed_guideline_index_vp AS (
    SELECT *
    FROM int_gtfs_quality__rt_feed_guideline_index
    WHERE feed_type = 'vehicle_positions'
)

SELECT * FROM int_gtfs_quality__rt_feed_guideline_index_vp
