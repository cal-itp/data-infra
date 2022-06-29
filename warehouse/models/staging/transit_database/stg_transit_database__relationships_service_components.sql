{{ config(materialized='table') }}

WITH
latest AS (
    {{ get_latest_external_data(
        external_table = source('airtable', 'transit_technology_stacks__relationships_service_components'),
        order_by = 'dt DESC, time DESC'
        ) }}
),

stg_transit_database__relationships_service_components AS (
    SELECT * EXCEPT(name),
    {{ trim_make_empty_string_null(column_name = "name") }}
    FROM latest
)

SELECT * FROM stg_transit_database__relationships_service_components
