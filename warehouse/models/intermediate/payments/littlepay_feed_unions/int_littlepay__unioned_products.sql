{{ config(materialized = "table") }}

WITH product_data_v1 AS (
    SELECT *
    FROM {{ ref('stg_littlepay__product_data') }}
),

products_v3 AS (
    SELECT *
    FROM {{ ref('stg_littlepay__products_v3') }}
),

int_littlepay__unioned_products AS (
    SELECT *
    FROM product_data_v1
    UNION ALL
    SELECT * FROM products_v3
)

SELECT * FROM int_littlepay__unioned_products
