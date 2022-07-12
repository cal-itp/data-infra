

WITH
latest AS (
    {{ get_latest_dense_rank(
        external_table = source('airtable', 'transit_technology_stacks__products'),
        order_by = 'time DESC', partition_by = 'dt'
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
    FROM latest
)

SELECT * FROM stg_transit_database__products
