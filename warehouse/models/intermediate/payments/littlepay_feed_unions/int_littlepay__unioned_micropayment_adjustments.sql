{{ config(materialized = "table") }}

WITH micropayment_adjustments_v1 AS (
    SELECT *
    FROM {{ ref('stg_littlepay__micropayment_adjustments') }}
    -- For agencies that had v1 feeds, keep everything before cutover date
    WHERE littlepay_export_date <= '2025-05-16'
),

micropayment_adjustments_v3 AS (
    SELECT *
    FROM {{ ref('stg_littlepay__micropayment_adjustments_v3') }}
    WHERE
        -- Keep all records for Nevada County Connects and SacRT, these agencies didn't have a competing feed v1 so we keep it all
        participant_id IN ('nevada-county-connects', 'sacrt')

        -- For the following participants only, keep records after 5/17/2025 (cutover date for agencies that had both feeds at some point)
        OR (
            participant_id IN ('clean-air-express', 'mendocino-transit-authority', 'ccjpa', 'atn', 'mst', 'lake-transit-authority', 'sbmtd', 'humboldt-transit-authority', 'redwood-coast-transit')
            AND littlepay_export_date > '2025-05-17'
        )
),

int_littlepay__unioned_micropayment_adjustments AS (
    SELECT *
    FROM micropayment_adjustments_v1
    UNION ALL
    SELECT * FROM micropayment_adjustments_v3
)

SELECT * FROM int_littlepay__unioned_micropayment_adjustments
