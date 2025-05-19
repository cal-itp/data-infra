{{ config(materialized = "table") }}

WITH product_data_v1 AS (
    SELECT *
    FROM {{ ref('stg_littlepay__product_data') }}
    WHERE littlepay_export_date <= '2025-05-16'
),

product_data_v3 AS (
    SELECT *
    FROM {{ ref('stg_littlepay__product_data_v3') }}
    WHERE
        -- Keep all records for Nevada County Connects and SacRT
        participant_id IN ('nevada-county-connects', 'sacrt')

        -- For the following participants only keep records after 5/17/2025
        OR (
            participant_id IN ('clean-air-express', 'mendocino-transit-authority', 'ccjpa', 'atn', 'mst', 'lake-transit-authority', 'sbmtd', 'humboldt-transit-authority', 'redwood-coast-transit')
            AND littlepay_export_date > '2025-05-17'
        )
),

int_littlepay__unioned_product_data AS (
    SELECT *
    FROM product_data_v1
    UNION ALL
    SELECT * FROM product_data_v3
)

SELECT * FROM int_littlepay__unioned_product_data
