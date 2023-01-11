{{ config(materialized='table') }}

WITH dim AS (
    SELECT *
    FROM {{ ref('int_transit_database__products_dim') }}
),

dim_products AS (
    SELECT
        key,
        original_record_id,
        name,
        url,
        requirements,
        notes,
        connectivity,
        certifications,
        product_features,
        business_model_features,
        _is_current,
        _valid_from,
        _valid_to
    FROM dim
)

SELECT * FROM dim_products
