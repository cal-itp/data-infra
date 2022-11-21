{{ config(materialized='table') }}

WITH gtfs_rt_validation_code_descriptions_legacy AS (
    SELECT *
    FROM {{ source('gtfs_rt_raw', 'validation_code_descriptions') }}
)

SELECT * FROM gtfs_rt_validation_code_descriptions_legacy
