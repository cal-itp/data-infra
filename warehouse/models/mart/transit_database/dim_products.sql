{{ config(materialized='table') }}

WITH stg_transit_database__products AS (
    SELECT * FROM {{ ref('stg_transit_database__products') }}
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
    FROM stg_transit_database__products
)

SELECT * FROM dim_products
