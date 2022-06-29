{{ config(materialized='table') }}

WITH stg_transit_database__services AS (
    SELECT * FROM {{ ref('stg_transit_database__services') }}
),

dim_services AS (
    SELECT
        key,
        name,
        service_type,
        mode,
        currently_operating,
        calitp_extracted_at
    FROM stg_transit_database__services
)

SELECT * FROM dim_services
