{{ config(materialized='table') }}

-- from https://gist.github.com/ewhauser/d7dd635ad2d4b20331c7f18038f04817

WITH pathways_clean AS (
    SELECT *
    FROM {{ ref('pathways_clean') }}
),
gtfs_schedule_dim_pathways AS (
  SELECT * FROM pathways_clean
),
SELECT * FROM gtfs_schedule_dim_pathways
