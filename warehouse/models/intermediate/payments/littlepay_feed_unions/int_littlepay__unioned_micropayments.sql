{{ config(materialized = "table") }}

WITH micropayments_v1 AS (
    SELECT
        micropayment_id,
        aggregation_id,
        participant_id,
        customer_id,
        funding_source_vault_id,
        transaction_time,
        payment_liability,
        charge_amount,
        nominal_amount,
        currency_code,
        type,
        charge_type,
        status,
        _line_number,
        `instance`,
        feed_version,
        extract_filename,
        ts,
        littlepay_export_ts,
        littlepay_export_date,
        _content_hash,
        _key,
        _payments_key,
    FROM {{ ref('stg_littlepay__micropayments') }}
    -- For agencies that had v1 feeds, keep everything before cutover date
    WHERE littlepay_export_date <= '2025-05-16'
),

micropayments_v3 AS (
    SELECT
        micropayment_id,
        aggregation_id,
        participant_id,
        customer_id,
        funding_source_vault_id,
        transaction_time,
        payment_liability,
        charge_amount,
        nominal_amount,
        currency_code,
        type,
        charge_type,
        status,
        _line_number,
        `instance`,
        feed_version,
        extract_filename,
        ts,
        littlepay_export_ts,
        littlepay_export_date,
        _content_hash,
        _key,
        _payments_key,
    FROM {{ ref('stg_littlepay__micropayments_v3') }}
    WHERE
        -- Keep all records for agencies that didn't have a competing feed v1
        participant_id NOT IN ('clean-air-express', 'mendocino-transit-authority', 'ccjpa', 'atn', 'mst', 'lake-transit-authority', 'sbmtd', 'humboldt-transit-authority', 'redwood-coast-transit')

        -- For the following participants only, keep records including and after 5/17/2025 (cutover date for agencies that had a feed v1)
        OR (
            participant_id IN ('clean-air-express', 'mendocino-transit-authority', 'ccjpa', 'atn', 'mst', 'lake-transit-authority', 'sbmtd', 'humboldt-transit-authority', 'redwood-coast-transit')
            AND littlepay_export_date >= '2025-05-17'
        )
),

int_littlepay__unioned_micropayments AS (
    SELECT *
    FROM micropayments_v1
    UNION ALL
    SELECT * FROM micropayments_v3
)

SELECT * FROM int_littlepay__unioned_micropayments
