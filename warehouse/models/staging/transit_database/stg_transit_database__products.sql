WITH

once_daily_products AS (
    {{ get_latest_dense_rank(
        external_table = source('airtable', 'transit_technology_stacks__products'),
        order_by = 'ts DESC', partition_by = 'dt'
        ) }}
),

stg_transit_database__products AS (
    SELECT
        id,
        {{ trim_make_empty_string_null(column_name = "name") }} AS name,
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
        dt
    FROM once_daily_products
)

SELECT * FROM stg_transit_database__products
