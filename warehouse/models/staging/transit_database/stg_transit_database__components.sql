{{ config(materialized='table') }}

WITH
latest AS (
    {{ get_latest_external_data(
        external_table_name = source('airtable', 'transit_technology_stacks__components'),
        columns = 'dt DESC, time DESC'
        ) }}
),

stg_transit_database__components AS (
    SELECT
        component_id as id,
        name as component_name,
        aliases,
        description,
        function_group,
        system,
        location,
        organization_stack_components as service_components,
        products,
        properties_and_features,
        dt as calitp_extracted_at
    FROM latest
)

SELECT * FROM stg_transit_database__components
