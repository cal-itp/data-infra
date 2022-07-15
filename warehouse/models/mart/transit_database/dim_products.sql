{{ config(materialized='table') }}

WITH latest_products AS (
    {{ get_latest_dense_rank(
        external_table = ref('stg_transit_database__products'),
        order_by = 'calitp_extracted_at DESC'
        ) }}
),

dim_products AS (
    SELECT
        key,
        name,
        url,
        requirements,
        notes,
        connectivity,
        certifications,
        product_features,
        business_model_features,
        calitp_extracted_at
    FROM latest_products
)

SELECT * FROM dim_products
