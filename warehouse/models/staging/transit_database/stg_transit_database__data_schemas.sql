{{ config(materialized='table') }}

WITH
latest AS (
    {{ get_latest_external_data(
        external_table_name = source('airtable', 'transit_technology_stacks__data_schemas'),
        columns = 'dt DESC, time DESC'
        ) }}
),

stg_transit_database__data_schemas AS (
    SELECT
        data_schema_id as id,
        name,
        status,
        products AS input_products,
        products_copy AS output_products,
        dt as calitp_extracted_at
    FROM latest
)

SELECT * FROM stg_transit_database__data_schemas
