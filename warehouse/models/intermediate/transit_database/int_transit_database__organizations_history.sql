{{ config(materialized='table') }}

WITH stg_transit_database__organizations AS (
    SELECT *
    FROM {{ ref('stg_transit_database__organizations') }}
),

int_gtfs_quality__organizations_history AS (
    SELECT
        calitp_extracted_at AS date,
        key,
        name,
        assessment_status,
        reporting_category,
        mobility_services_managed
    FROM stg_transit_database__organizations
)

SELECT * FROM int_gtfs_quality__organizations_history
