{{ config(materialized='table') }}

WITH gtfs_schedule_dim_shapes_geo AS (
    SELECT *
    FROM {{ ref('gtfs_schedule_dim_shapes_geo') }}
),

gtfs_schedule_dim_shapes_geo_latest AS (
    SELECT *
    FROM gtfs_schedule_dim_shapes_geo
    WHERE calitp_deleted_at = '2099-01-01'
)

SELECT * FROM gtfs_schedule_dim_shapes_geo_latest
