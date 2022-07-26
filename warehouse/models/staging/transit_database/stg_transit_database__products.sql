

WITH
once_daily_products AS (
    {{ get_latest_dense_rank(
        external_table = source('airtable', 'transit_technology_stacks__products'),
        order_by = 'ts DESC', partition_by = 'dt'
        ) }}
),

stg_transit_database__products AS (
    SELECT
        id AS key,
        {{ trim_make_empty_string_null(column_name = "name") }},
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
    FROM once_daily_products
)

SELECT * FROM stg_transit_database__products
