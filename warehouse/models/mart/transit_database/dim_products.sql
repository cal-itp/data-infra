{{ config(materialized='table') }}

WITH dim AS (
    SELECT *
    FROM {{ ref('int_transit_database__products_dim') }}
),

dim_products AS (
    SELECT
        key,
        source_record_id,
        name,
        url,
        requirements,
        notes,
        connectivity,
        certifications,
        product_features,
        business_model_features,
        start_date,
        end_date,
        status,
        cal_itp_product,
        _is_current,
        _valid_from,
        _valid_to
    FROM dim
)

SELECT * FROM dim_products
