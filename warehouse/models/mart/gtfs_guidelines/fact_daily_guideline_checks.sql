{{ config(materialized='table') }}

-- start query
WITH stg_gtfs_guidelines__schedule_downloaded_successfully AS (
    SELECT * FROM {{ ref('stg_gtfs_guidelines__schedule_downloaded_successfully') }}
),

stg_gtfs_guidelines__no_validation_errors AS (
    SELECT * FROM {{ ref('stg_gtfs_guidelines__no_validation_errors') }}
),

stg_gtfs_guidelines__complete_wheelchair_accessibility_data AS (
    SELECT * FROM {{ ref('stg_gtfs_guidelines__complete_wheelchair_accessibility_data') }}
),

stg_gtfs_guidelines__shapes_file_present AS (
    SELECT * FROM {{ ref('stg_gtfs_guidelines__shapes_file_present') }}
),

stg_gtfs_guidelines__shapes_valid AS (
    SELECT * FROM {{ ref('stg_gtfs_guidelines__shapes_valid') }}
),

stg_gtfs_guidelines__technical_contact_listed AS (
    SELECT * FROM {{ ref('stg_gtfs_guidelines__technical_contact_listed') }}
),

fact_daily_guideline_checks AS (
    SELECT
        {{ gtfs_guidelines_columns() }}
    FROM stg_gtfs_guidelines__schedule_downloaded_successfully
    UNION ALL
    SELECT
        {{ gtfs_guidelines_columns() }}
    FROM stg_gtfs_guidelines__no_validation_errors
    UNION ALL
    SELECT
        {{ gtfs_guidelines_columns() }}
    FROM stg_gtfs_guidelines__complete_wheelchair_accessibility_data
    UNION ALL
    SELECT
        {{ gtfs_guidelines_columns() }}
    FROM stg_gtfs_guidelines__shapes_file_present
    UNION ALL
    SELECT
        {{ gtfs_guidelines_columns() }}
    FROM stg_gtfs_guidelines__shapes_valid
    UNION ALL
    SELECT
        {{ gtfs_guidelines_columns() }}
    FROM stg_gtfs_guidelines__technical_contact_listed
)

SELECT * FROM fact_daily_guideline_checks
