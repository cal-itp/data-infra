{{ config(materialized='table') }}

WITH validation_notices AS (
    SELECT *
    FROM {{ ref('stg_gtfs_schedule__validation_notices') }}
),

int_gtfs_quality__schedule_validation_severities AS (
    SELECT DISTINCT
        code,
        severity,
        gtfs_validator_version,
    FROM validation_notices
)

SELECT * FROM int_gtfs_quality__schedule_validation_severities
