{{ config(materialized='table') }}

WITH int_transit_database__service_components AS (
    SELECT *
    FROM {{ ref('int_transit_database__service_components_dim') }}
),

dim_service_components AS (
    SELECT
        key,
        source_record_id,
        service_key,
        service_name,
        product_key,
        product_name,
        product_vendor_organization_key,
        product_vendor_organization_name,
        component_key,
        component_name,
        ntd_certified,
        product_component_valid,
        notes,
        start_date,
        end_date,
        is_active,
        service_source_record_id,
        product_source_record_id,
        product_vendor_organization_source_record_id,
        component_source_record_id,
        _is_current,
        _valid_from,
        _valid_to
    FROM int_transit_database__service_components
)

SELECT * FROM dim_service_components
