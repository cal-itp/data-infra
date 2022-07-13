{{ config(materialized='table') }}

WITH stg_transit_database__services AS (
    SELECT * FROM {{ ref('stg_transit_database__services') }}
),

unnest_paratransit AS (
    SELECT
        key AS service_key,
        name AS service_name,
        paratransit_for AS paratransit_for_service_key
    FROM stg_transit_database__services,
        stg_transit_database__services.paratransit_for AS paratransit_for
),

bridge_paratransit_services AS (
    SELECT
        t1.*,
        t2.name AS paratransit_for_service_name
    FROM unnest_paratransit AS t1
    LEFT JOIN stg_transit_database__services AS t2
        ON t1.paratransit_for_service_key = t2.key
)

SELECT * FROM bridge_paratransit_services
