{{ config(materialized = "table") }}

WITH micropayments_v1 AS (
    SELECT *
    FROM {{ ref('stg_littlepay__micropayments') }}
    WHERE littlepay_export_date <= '2025-05-16'
),

micropayments_v3 AS (
    SELECT *
    FROM {{ ref('stg_littlepay__micropayments_v3') }}
    WHERE
        -- Keep all records for Nevada County Connects and SacRT
        participant_id IN ('nevada-county-connects', 'sacrt')

        -- For the following participants only keep records after 5/17/2025
        OR (
            participant_id IN ('clean-air-express', 'mendocino-transit-authority', 'ccjpa', 'atn', 'mst', 'lake-transit-authority', 'sbmtd', 'humboldt-transit-authority', 'redwood-coast-transit')
            AND littlepay_export_date > '2025-05-17'
        )
),

int_littlepay__unioned_micropayments AS (
    SELECT *
    FROM micropayments_v1
    UNION ALL
    SELECT * FROM micropayments_v3
)

SELECT * FROM int_littlepay__unioned_micropayments
