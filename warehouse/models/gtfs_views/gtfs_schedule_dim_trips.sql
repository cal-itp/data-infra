{{ config(materialized='table') }}

WITH trips_clean AS (
    SELECT *
    FROM {{ ref('trips_clean') }}
),
gtfs_schedule_dim_trips AS (
  SELECT * FROM trips_clean
)
SELECT * FROM gtfs_schedule_dim_trips
