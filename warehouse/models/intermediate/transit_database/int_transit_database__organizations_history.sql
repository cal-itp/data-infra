{{ config(materialized='table') }}

WITH stg_transit_database__organizations AS (
    SELECT *
    FROM {{ ref('stg_transit_database__organizations') }}
),

int_gtfs_quality__organizations_history AS (
    SELECT
        calitp_extracted_at AS date,
        {{ dbt_utils.surrogate_key(['key', 'unnested_service']) }} AS key,
        key AS organization_key,
        name,
        assessment_status,
        reporting_category,
        unnested_service AS mobility_services_managed_service_key
    FROM stg_transit_database__organizations
    CROSS JOIN UNNEST(stg_transit_database__organizations.mobility_services_managed) AS unnested_service
)

SELECT * FROM int_gtfs_quality__organizations_history
