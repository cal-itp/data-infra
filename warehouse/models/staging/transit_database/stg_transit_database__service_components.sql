{{ config(materialized='table') }}

WITH
latest AS (
    {{ get_latest_external_data(
        external_table_name = source('airtable', 'transit_technology_stacks__service_components'),
        columns = 'dt DESC, time DESC'
        ) }}
),

stg_transit_database__service_components AS (
    SELECT
        service_component_id AS key,
        name,
        ntd_certified,
        product_component_valid,
        notes,
        services,
        component,
        product,
        contracts,
    FROM latest
)

SELECT * FROM stg_transit_database__service_components
