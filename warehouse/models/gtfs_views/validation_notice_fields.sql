{{ config(materialized='table') }}

WITH validation_notice_fields AS (
    SELECT *
    FROM {{ source('gtfs_schedule_history',
    'validation_notice_fields') }}
)

SELECT * FROM validation_notice_fields
