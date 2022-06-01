{{ config(materialized='table') }}

WITH
latest AS (
    {{ get_latest_external_data(
        external_table_name = source('airtable', 'transit_technology_stacks__products'),
        columns = 'dt DESC, time DESC'
        ) }}
),

stg_transit_database__products AS (
    SELECT
        product_id AS id,
        name,
        url,
        requirements,
        notes,
        connectivity,
        certifications,
        product_features,
        business_model_features,
        organization_stack_components,
        accepted_input_components,
        output_components,
        components,
        dt AS calitp_extracted_at
    FROM latest
)

SELECT * FROM stg_transit_database__products
