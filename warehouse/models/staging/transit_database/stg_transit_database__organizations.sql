WITH

stg_transit_database__organizations AS (
    SELECT * FROM {{ ref('base_california_transit__organizations') }}
)

SELECT * FROM stg_transit_database__organizations
