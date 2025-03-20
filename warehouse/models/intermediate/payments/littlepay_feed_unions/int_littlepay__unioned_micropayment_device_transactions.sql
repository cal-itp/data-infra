{{ config(materialized = "table") }}

WITH micropayment_device_transactions_v1 AS (
    SELECT *
    FROM {{ ref('stg_littlepay__micropayment_device_transactions') }}
),

micropayment_device_transactions_v3 AS (
    SELECT *
    FROM {{ ref('stg_littlepay__micropayment_device_transactions_v3') }}
),

int_littlepay__unioned_micropayment_device_transactions AS (
    SELECT *
    FROM micropayment_device_transactions_v1
    UNION ALL
    SELECT * FROM micropayment_device_transactions_v3
)

SELECT * FROM int_littlepay__unioned_micropayment_device_transactions
