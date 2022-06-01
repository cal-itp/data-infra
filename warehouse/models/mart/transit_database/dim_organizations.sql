{{ config(materialized='table') }}

WITH stg_transit_database__organizations AS (
    SELECT * FROM {{ ref('stg_transit_database__organizations') }}
),

dim_organizations AS (
    SELECT
        id,
        name,
        organization_type,
        roles,
        itp_id,
        details,
        caltrans_district,
        calitp_extracted_at
    FROM stg_transit_database__organizations
)

SELECT * FROM dim_organizations
