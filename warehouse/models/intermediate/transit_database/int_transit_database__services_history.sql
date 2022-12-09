{{ config(materialized='table') }}

WITH stg_transit_database__services AS (
    SELECT *
    FROM {{ ref('stg_transit_database__services') }}
),

int_gtfs_quality__services_history AS (
    SELECT
        calitp_extracted_at AS date,
        key,
        name,
        assessment_status,
        currently_operating,
        service_type,
        provider
    FROM stg_transit_database__services
)

SELECT * FROM int_gtfs_quality__services_history
