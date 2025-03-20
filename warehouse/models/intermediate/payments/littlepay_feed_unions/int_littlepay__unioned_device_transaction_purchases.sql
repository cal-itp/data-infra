{{ config(materialized = "table") }}

WITH device_transaction_purchases_v1 AS (
    SELECT *
    FROM {{ ref('stg_littlepay__device_transaction_purchases') }}
),

device_transaction_purchases_v3 AS (
    SELECT *
    FROM {{ ref('stg_littlepay__device_transaction_purchases_v3') }}
),

int_littlepay__unioned_device_transaction_purchases AS (
    SELECT *
    FROM device_transaction_purchases_v1
    UNION ALL
    SELECT * FROM device_transaction_purchases_v3
)

SELECT * FROM int_littlepay__unioned_device_transaction_purchases
