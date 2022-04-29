{{ config(materialized='table') }}

WITH gtfs_rt_validation_code_descriptions AS (
    SELECT *
    FROM {{ source('gtfs_rt',
    'validation_code_descriptions') }}
)

SELECT * FROM gtfs_rt_validation_code_descriptions
