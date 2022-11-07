{{ config(materialized='table') }}

WITH validation_notices AS (
    SELECT *
    FROM {{ ref('stg_gtfs_schedule__validation_notices') }}
),

int_gtfs_guidelines_v2__schedule_validation_severities AS (
    -- TODO: if a future version of the validator changes a codes severity
    -- we will end up with multiple entries for code (our primary key)
    -- we either need to change track this table, or use only the most recent
    -- levels of code x severity
    SELECT DISTINCT
        code,
        severity
    FROM validation_notices
)

SELECT * FROM int_gtfs_guidelines_v2__schedule_validation_severities
