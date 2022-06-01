{{ config(materialized='table') }}

WITH
stg_transit_database__properties_and_features AS (
    {{ get_latest_external_data(
        external_table_name = source('airtable', 'transit_technology_stacks__properties_and_features'),
        columns = 'dt DESC, time DESC'
        ) }}
)

SELECT * FROM stg_transit_database__properties_and_features
