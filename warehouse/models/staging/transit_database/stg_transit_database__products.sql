WITH

once_daily_products AS (
    SELECT *
    -- have to use base table to get the california transit base organization record ids
    FROM {{ ref('base_tts_products_idmap') }}
),

stg_transit_database__products AS (
    SELECT
        id,
        {{ trim_make_empty_string_null(column_name = "name") }} AS name,
        url,
        requirements,
        notes,
        connectivity,
        unnested_vendor AS vendor_organization_source_record_id,
        certifications,
        product_features,
        business_model_features,
        organization_stack_components,
        accepted_input_components,
        output_components,
        components,
        start_date,
        end_date,
        status,
        cal_itp_product,
        dt
    FROM once_daily_products
    LEFT JOIN UNNEST(once_daily_products.vendor) AS unnested_vendor
)

SELECT * FROM stg_transit_database__products
