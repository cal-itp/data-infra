{{ config(materialized='table') }}

-- start query
WITH stg_gtfs_guidelines__schedule_downloaded_successfully AS (
    SELECT * FROM {{ ref('stg_gtfs_guidelines__schedule_downloaded_successfully') }}
),

stg_gtfs_guidelines__no_validation_errors_in_last_30_days AS (
    SELECT * FROM {{ ref('stg_gtfs_guidelines__no_validation_errors_in_last_30_days') }}
),

gtfs_schedule_fact_daily_guideline_checks AS (
    SELECT * FROM stg_gtfs_guidelines__schedule_downloaded_successfully
    UNION ALL
    SELECT * FROM stg_gtfs_guidelines__no_validation_errors_in_last_30_days
)

SELECT * FROM gtfs_schedule_fact_daily_guideline_checks
