{{ config(materialized='table') }}

WITH int_transit_database__service_components AS (
    SELECT *
    FROM {{ ref('int_transit_database__service_components_dim') }}
),

dim_service_components AS (
    SELECT
        key,
        service_key,
        service_name,
        product_key,
        product_name,
        component_key,
        component_name,
        ntd_certified,
        product_component_valid,
        notes,
        _is_current,
        _valid_from,
        _valid_to
    FROM int_transit_database__service_components
)

SELECT * FROM dim_service_components
