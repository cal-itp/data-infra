{{ config(materialized='table') }}

WITH
stg_transit_database__contracts AS (
    {{ get_latest_external_data(
        external_table_name = source('airtable', 'transit_technology_stacks__contracts'),
        columns = 'dt DESC, time DESC'
        ) }}
)

SELECT * FROM stg_transit_database__contracts
