{{ config(materialized='table') }}

WITH stg_transit_database__services AS (
    SELECT *
    FROM {{ ref('stg_transit_database__services') }}
),

int_transit_database__services_history AS (
    SELECT
        calitp_extracted_at AS date,
        {{ dbt_utils.surrogate_key(['key', 'unnest_provider']) }} AS key,
        key AS service_key,
        name,
        assessment_status,
        currently_operating,
        ARRAY_TO_STRING(service_type, ",") AS service_type_str,
        unnest_provider AS provider_organization_key,
    FROM stg_transit_database__services
    CROSS JOIN UNNEST(stg_transit_database__services.provider) AS unnest_provider

)

SELECT * FROM int_transit_database__services_history
