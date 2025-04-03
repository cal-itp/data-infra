{{ config(materialized = "table") }}

WITH product_data_v1 AS (
    SELECT *
    FROM {{ ref('stg_littlepay__product_data') }}
),

product_data_v3 AS (
    SELECT *
    FROM {{ ref('stg_littlepay__product_data_v3') }}
),

int_littlepay__unioned_product_data AS (
    SELECT *
    FROM product_data_v1
    UNION ALL
    SELECT * FROM product_data_v3
)

SELECT * FROM int_littlepay__unioned_product_data
