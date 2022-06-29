{{ config(materialized='table') }}

WITH stg_transit_database__service_components AS (
    SELECT * FROM {{ ref('stg_transit_database__service_components') }}
),

dim_components AS (
    SELECT * FROM {{ ref('dim_components') }}
),

dim_services AS (
    SELECT * FROM {{ ref('dim_services') }}
),

dim_products AS (
    SELECT * FROM {{ ref('dim_products') }}
),

dim_contracts AS (
    SELECT * FROM {{ ref('dim_contracts') }}
),


unnest_service_components AS (
    SELECT
        service_key,
        product_key,
        contract_key,
        component_key,
        ntd_certified,
        product_component_valid,
        notes
    FROM stg_transit_database__service_components
    LEFT JOIN UNNEST(stg_transit_database__service_components.services) AS service_key
    LEFT JOIN UNNEST(stg_transit_database__service_components.product) AS product_key
    LEFT JOIN UNNEST(stg_transit_database__service_components.contracts) AS contract_key
    LEFT JOIN UNNEST(stg_transit_database__service_components.component) AS component_key
    -- check that we have service and product actually defined
    WHERE (service_key IS NOT NULL) AND (product_key IS NOT NULL)
),

map_services_x_products AS (
    SELECT
        t1.service_key,
        t2.name AS service_name,
        t1.product_key,
        t3.name AS product_name,
        t1.contract_key,
        t4.name AS contract_name,
        t1.component_key,
        t5.name AS component_name,
        t1.ntd_certified,
        t1.product_component_valid,
        t1.notes
    FROM unnest_service_components AS t1
    LEFT JOIN dim_services AS t2
        ON t1.service_key = t2.key
    LEFT JOIN dim_products AS t3
        ON t1.product_key = t3.key
    LEFT JOIN dim_contracts AS t4
        ON t1.contract_key = t4.key
    LEFT JOIN dim_components AS t5
        ON t1.component_key = t5.key
)

SELECT * FROM map_services_x_products
