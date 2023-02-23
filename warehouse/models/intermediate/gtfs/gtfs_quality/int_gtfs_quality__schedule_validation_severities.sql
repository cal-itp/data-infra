{{ config(materialized='table') }}

WITH validator_details AS (
    SELECT *
    FROM {{ ref('int_gtfs_quality__schedule_validator_rule_details_unioned') }}
),

int_gtfs_quality__schedule_validation_severities AS (
    SELECT DISTINCT
        code,
        severity,
        version AS gtfs_validator_version,
    FROM validator_details
    -- we don't want to include system errors in our notices tables
    -- generally they would mean validator did not run correctly, which would be captured as a validation outcome
    WHERE severity != 'SYSTEM_ERROR'
)

SELECT * FROM int_gtfs_quality__schedule_validation_severities
