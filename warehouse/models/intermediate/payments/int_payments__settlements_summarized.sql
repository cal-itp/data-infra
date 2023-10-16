{{ config(materialized = 'table',) }}

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

summarize_by_type AS (
    SELECT
        participant_id,
        aggregation_id,
        retrieval_reference_number,
        settlement_type,
        LOGICAL_OR(imputed_type) AS type_contains_imputed_type,
        MAX(settlement_requested_date_time_utc) AS type_latest_update_timestamp,
        CASE
            WHEN settlement_type = "CREDIT" THEN -1*SUM(transaction_amount)
            WHEN settlement_type = "DEBIT" THEN SUM(transaction_amount)
        END AS total_amount,
    FROM impute_settlement_type
    GROUP BY 1, 2, 3, 4
),

-- group again to get overall summary across types
summarize_overall AS (
    SELECT
        participant_id,
        aggregation_id,
        retrieval_reference_number,
        LOGICAL_OR(type_contains_imputed_type) AS contains_imputed_type,
        MAX(type_latest_update_timestamp) AS latest_update_timestamp,
        SUM(total_amount) AS net_amount,
    FROM summarize_by_type
    GROUP BY 1, 2, 3
),

int_payments__settlements_summarized AS (
    SELECT
        summary.participant_id,
        summary.aggregation_id,
        summary.retrieval_reference_number,
        contains_imputed_type,
        latest_update_timestamp,
        net_amount AS net_settled_amount_dollars,
        COALESCE(debit.total_amount,0) AS debit_amount,
        COALESCE(credit.total_amount,0) AS credit_amount
    FROM summarize_overall AS summary
    LEFT JOIN summarize_by_type AS debit
        ON summary.aggregation_id = debit.aggregation_id
        AND summary.retrieval_reference_number = debit.retrieval_reference_number
        AND debit.settlement_type = "DEBIT"
    LEFT JOIN summarize_by_type AS credit
        ON summary.aggregation_id = credit.aggregation_id
        AND summary.retrieval_reference_number = credit.retrieval_reference_number
        AND credit.settlement_type = "CREDIT"
)

SELECT * FROM int_payments__settlements_summarized
