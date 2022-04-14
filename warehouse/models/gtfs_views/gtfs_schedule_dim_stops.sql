{{ config(materialized='table') }}

WITH stops_clean AS (
    SELECT *
    FROM {{ ref('stops_clean') }}
),
gtfs_schedule_dim_stops AS (
  SELECT * FROM stops_clean
)
SELECT * FROM gtfs_schedule_dim_stops
