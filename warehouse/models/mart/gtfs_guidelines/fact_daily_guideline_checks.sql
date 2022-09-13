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

stg_gtfs_guidelines__pathways_valid AS (
    SELECT * FROM {{ ref('stg_gtfs_guidelines__pathways_valid') }}
),

stg_gtfs_guidelines__technical_contact_listed AS (
    SELECT * FROM {{ ref('stg_gtfs_guidelines__technical_contact_listed') }}
),

stg_gtfs_guidelines__no_rt_critical_validation_errors AS (
    SELECT * FROM {{ ref('stg_gtfs_guidelines__no_rt_critical_validation_errors') }}
),

stg_gtfs_guidelines__trip_id_alignment AS (
    SELECT * FROM {{ ref('stg_gtfs_guidelines__trip_id_alignment') }}
),

stg_gtfs_guidelines__vehicle_positions_feed_present AS (
    SELECT * FROM {{ ref('stg_gtfs_guidelines__vehicle_positions_feed_present') }}
),

stg_gtfs_guidelines__trip_updates_feed_present AS (
    SELECT * FROM {{ ref('stg_gtfs_guidelines__trip_updates_feed_present') }}
),

stg_gtfs_guidelines__service_alerts_feed_present AS (
    SELECT * FROM {{ ref('stg_gtfs_guidelines__service_alerts_feed_present') }}
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
    FROM stg_gtfs_guidelines__pathways_valid
    UNION ALL
    SELECT
        {{ gtfs_guidelines_columns() }}
    FROM stg_gtfs_guidelines__technical_contact_listed
    UNION ALL
    SELECT
        {{ gtfs_guidelines_columns() }}
    FROM stg_gtfs_guidelines__no_rt_critical_validation_errors
    UNION ALL
    SELECT
        {{ gtfs_guidelines_columns() }}
    FROM stg_gtfs_guidelines__trip_id_alignment
    UNION ALL
    SELECT
        {{ gtfs_guidelines_columns() }}
    FROM stg_gtfs_guidelines__vehicle_positions_feed_present
    UNION ALL
    SELECT
        {{ gtfs_guidelines_columns() }}
    FROM stg_gtfs_guidelines__trip_updates_feed_present
    UNION ALL
    SELECT
        {{ gtfs_guidelines_columns() }}
    FROM stg_gtfs_guidelines__service_alerts_feed_present
)

SELECT * FROM fact_daily_guideline_checks