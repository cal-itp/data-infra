{{ config(materialized='table') }}

WITH gtfs_schedule_dim_shapes_geo AS (
    SELECT *
    FROM {{ ref('gtfs_schedule_dim_shapes_geo') }}
),

gtfs_schedule_dim_shapes_geo_latest AS (
    -- TODO: we should probably timestamp these in some way
    SELECT * EXCEPT (calitp_extracted_at, calitp_deleted_at)
    FROM gtfs_schedule_dim_shapes_geo
    WHERE calitp_deleted_at = '2099-01-01'
)

SELECT * FROM gtfs_schedule_dim_shapes_geo_latest
