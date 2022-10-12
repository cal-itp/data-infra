WITH

stg_transit_database__services AS (
    SELECT * FROM {{ ref('base_california_transit__services') }}
)

SELECT * FROM stg_transit_database__services
