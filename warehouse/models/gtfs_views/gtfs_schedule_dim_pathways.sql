{{ config(materialized='table') }}

WITH pathways_clean AS (
    SELECT *
    FROM {{ ref('pathways_clean') }}
),
gtfs_schedule_dim_pathways AS (
  SELECT * FROM pathways_clean
)
SELECT * FROM gtfs_schedule_dim_pathways
