{{ config(materialized = "table") }}

WITH device_transaction_purchases_v1 AS (
    SELECT *
    FROM {{ ref('stg_littlepay__device_transaction_purchases') }}
    WHERE littlepay_export_date <= '2025-05-16'
),

device_transaction_purchases_v3 AS (
    SELECT *
    FROM {{ ref('stg_littlepay__device_transaction_purchases_v3') }}
    WHERE
        -- Keep all records for Nevada County Connects and SacRT
        instance IN ('nevada-county-connects', 'sacrt')

        -- For the following participants only keep records after 5/17/2025
        OR (
            instance IN ('clean-air-express', 'mendocino-transit-authority', 'ccjpa', 'atn', 'mst', 'lake-transit-authority', 'sbmtd', 'humboldt-transit-authority', 'redwood-coast-transit')
            AND littlepay_export_date > '2025-05-17'
        )
),

int_littlepay__unioned_device_transaction_purchases AS (
    SELECT *
    FROM device_transaction_purchases_v1
    UNION ALL
    SELECT * FROM device_transaction_purchases_v3
)

SELECT * FROM int_littlepay__unioned_device_transaction_purchases
