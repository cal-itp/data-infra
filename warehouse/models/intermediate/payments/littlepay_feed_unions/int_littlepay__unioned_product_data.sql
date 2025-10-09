{{ config(materialized = "table") }}

WITH product_data_v1 AS (
    SELECT *
    FROM {{ ref('stg_littlepay__product_data') }}
    -- For agencies that had v1 feeds, keep everything before cutover date
    WHERE littlepay_export_date <= '2025-05-16'
),

product_data_v3 AS (
    SELECT *
    FROM {{ ref('stg_littlepay__product_data_v3') }}
    WHERE
        -- Keep all records for agencies that didn't have a competing feed v1
        participant_id NOT IN ('clean-air-express', 'mendocino-transit-authority', 'ccjpa', 'atn', 'mst', 'lake-transit-authority', 'sbmtd', 'humboldt-transit-authority', 'redwood-coast-transit')

        -- For the following participants only, keep records including and after 5/17/2025 (cutover date for agencies that had both feeds at some point)
        OR (
            participant_id IN ('clean-air-express', 'mendocino-transit-authority', 'ccjpa', 'atn', 'mst', 'lake-transit-authority', 'sbmtd', 'humboldt-transit-authority', 'redwood-coast-transit')
            AND littlepay_export_date >= '2025-05-17'
        )
),

int_littlepay__unioned_product_data AS (
    SELECT *
    FROM product_data_v1
    UNION ALL
    SELECT * FROM product_data_v3
)

SELECT * FROM int_littlepay__unioned_product_data
