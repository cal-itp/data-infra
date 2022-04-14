{{ config(materialized='table') }}

WITH shapes_clean AS (
    SELECT *
    FROM {{ ref('shapes_clean') }}
),
gtfs_schedule_dim_shapes AS (
  SELECT * FROM shapes_clean
)
SELECT * FROM gtfs_schedule_dim_shapes
