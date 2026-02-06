{{ config(materialized = "table") }}

WITH settlements_v1 AS (
    SELECT *
    FROM {{ ref('stg_littlepay__settlements') }}
    -- For agencies that had v1 feeds, keep everything before cutover date
    WHERE littlepay_export_date <= '2025-05-16'
),

settlements_v3 AS (
    SELECT *
    FROM {{ ref('stg_littlepay__settlements_v3') }}
    WHERE
        -- Keep all records for agencies that didn't have a competing feed v1
        participant_id NOT IN ('clean-air-express', 'mendocino-transit-authority', 'ccjpa', 'atn', 'mst', 'lake-transit-authority', 'sbmtd', 'humboldt-transit-authority', 'redwood-coast-transit')

        -- For the following participants only, keep records including and after 5/17/2025 (cutover date for agencies that had a feed v1)
        OR (
            participant_id IN ('clean-air-express', 'mendocino-transit-authority', 'ccjpa', 'atn', 'mst', 'lake-transit-authority', 'sbmtd', 'humboldt-transit-authority', 'redwood-coast-transit')
            AND littlepay_export_date >= '2025-05-17'
        )
),

union_versions AS (
    SELECT *
    FROM settlements_v1
    UNION ALL
    SELECT * FROM settlements_v3
),

int_littlepay__unioned_settlements AS (
    SELECT
        *
    FROM union_versions
    -- see: https://github.com/cal-itp/data-infra/issues/4552
    -- we have cases where same settlement comes in with two statuses
    -- only want to keep one instance -- the more recent one
    QUALIFY ROW_NUMBER() OVER
        (PARTITION BY participant_id, _payments_key, transaction_amount
        ORDER BY record_updated_timestamp_utc DESC, _line_number ASC) = 1
)

SELECT * FROM int_littlepay__unioned_settlements
