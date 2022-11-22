{{ config(materialized='table') }}

WITH validation_notices AS (
    SELECT *
    FROM {{ ref('stg_gtfs_schedule__validation_notices') }}
),

int_gtfs_quality__schedule_validation_severities AS (
    -- TODO: if a future version of the validator changes a codes severity
    -- we will end up with multiple entries for code (our primary key)
    -- we either need to change track this table, or use only the most recent
    -- levels of code x severity
    -- TODO: another option is to make this a seed built from later versions
    -- of the validator with the -n flag https://github.com/MobilityData/gtfs-validator/blob/master/docs/USAGE.md#via-cli-app
    SELECT DISTINCT
        code,
        severity
    FROM validation_notices
)

SELECT * FROM int_gtfs_quality__schedule_validation_severities
