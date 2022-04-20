{{ config(materialized='table') }}

WITH validation_code_descriptions AS (
    SELECT *
    FROM {{ source('gtfs_schedule_history',
    'validation_code_descriptions') }}
)

SELECT * FROM validation_code_descriptions
