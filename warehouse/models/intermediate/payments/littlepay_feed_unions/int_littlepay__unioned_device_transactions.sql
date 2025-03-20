{{ config(materialized = "table") }}

WITH device_transactions_v1 AS (
    SELECT *
    FROM {{ ref('stg_littlepay__device_transactions') }}
),

device_transactions_v3 AS (
    SELECT *
    FROM {{ ref('stg_littlepay__device_transactions_v3') }}
),

int_littlepay__unioned_device_transactions AS (
    SELECT *
    FROM device_transactions_v1
    UNION ALL
    SELECT * FROM device_transactions_v3
)

SELECT * FROM int_littlepay__unioned_device_transactions
