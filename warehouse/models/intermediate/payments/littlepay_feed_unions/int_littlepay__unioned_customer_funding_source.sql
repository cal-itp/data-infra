{{ config(materialized = "table") }}

WITH customer_funding_source_v1 AS (
    SELECT *
    FROM {{ ref('stg_littlepay__customer_funding_source') }}
),

customer_funding_source_v3 AS (
    SELECT *
    FROM {{ ref('stg_littlepay__customer_funding_source_v3') }}
),

int_littlepay__unioned_customer_funding_source AS (
    SELECT *
    FROM customer_funding_source_v1
    UNION ALL
    SELECT * FROM customer_funding_source_v3
)

SELECT * FROM int_littlepay__unioned_customer_funding_source
