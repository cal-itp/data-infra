{{ config(materialized = 'table',
    post_hook="{{ payments_row_access_policy() }}") }}

WITH settlements AS (
    SELECT *
    FROM {{ ref('stg_littlepay__settlements') }}
),

-- some rows have null settlement type (debit vs. credit)
-- so we try to impute based on settlement order
impute_settlement_type AS (
    SELECT
        * EXCEPT(settlement_type),
        COALESCE(settlement_type,
            -- when a settlement (aggregation_id / RRN) appears multiple times, it is generally because the subsequent lines are refunds
            -- vast majority of refunds have exactly one debit line and one credit (refund) line, but there are a few oddities with multiple credit (refund) lines
            CASE
                WHEN ROW_NUMBER() OVER(PARTITION BY aggregation_id, retrieval_reference_number ORDER BY settlement_requested_date_time_utc) > 1 THEN "CREDIT"
                ELSE "DEBIT"
            END
        ) AS settlement_type,
        settlement_type IS NULL AS imputed_type,
    FROM settlements
),

-- TODO: add "new schema" columns that are present only for ATN as of 10/6/23
fct_payments_settlements AS (
    SELECT
        settlement_id,
        participant_id,
        aggregation_id,
        customer_id,
        funding_source_id,
        retrieval_reference_number,
        littlepay_reference_number,
        external_reference_number,
        settlement_type,
        settlement_requested_date_time_utc,
        CASE
            WHEN settlement_type = "CREDIT" THEN -1*(transaction_amount)
            WHEN settlement_type = "DEBIT" THEN transaction_amount
        END AS transaction_amount,
        LAST_DAY(EXTRACT(DATE FROM settlement_requested_date_time_utc), MONTH) AS end_of_month_date,
        imputed_type,
        acquirer,
        _line_number,
        `instance`,
        extract_filename,
        ts,
        _content_hash,
        littlepay_export_ts,
        littlepay_export_date,
        _key,
        _payments_key
    FROM impute_settlement_type
)

SELECT * FROM fct_payments_settlements
