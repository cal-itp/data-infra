{{ config(materialized='table') }}

WITH
stg_transit_database__relationships_service_components AS (
    {{ get_latest_external_data(
        external_table_name = source('airtable', 'transit_technology_stacks__relationships_service_components'),
        columns = 'dt DESC, time DESC'
        ) }}
)

SELECT * FROM stg_transit_database__relationships_service_components
