{{ config(materialized = "table") }}

WITH refunds_v1 AS (
    SELECT
        * EXCEPT (proposed_amount, refund_amount),
        -- in v3, the interpretation of these columns was swapped
        -- in v1, proposed_amount is the amount to be refunded
        -- and in v1, refund_amount is transaction_amount - proposed_amount
        proposed_amount as refund_amount,
        refund_amount as proposed_amount
    FROM {{ ref('stg_littlepay__refunds') }}
    -- For agencies that had v1 feeds, keep everything before cutover date
    WHERE littlepay_export_date <= '2025-05-16'
),

refunds_v3 AS ( --noqa: ST03
    SELECT *
    FROM {{ ref('stg_littlepay__refunds_v3') }}
    WHERE
        -- Keep all records for agencies that didn't have a competing feed v1
        participant_id NOT IN ('clean-air-express', 'mendocino-transit-authority', 'ccjpa', 'atn', 'mst', 'lake-transit-authority', 'sbmtd', 'humboldt-transit-authority', 'redwood-coast-transit')

        -- For the following participants only, keep records including and after 5/17/2025 (cutover date for agencies that had a feed v1)
        OR (
            participant_id IN ('clean-air-express', 'mendocino-transit-authority', 'ccjpa', 'atn', 'mst', 'lake-transit-authority', 'sbmtd', 'humboldt-transit-authority', 'redwood-coast-transit')
            AND littlepay_export_date >= '2025-05-17'
        )
),

int_littlepay__unioned_refunds AS (
    SELECT *
    FROM refunds_v1
    UNION ALL BY NAME
    SELECT * FROM refunds_v3
)

SELECT * FROM int_littlepay__unioned_refunds
