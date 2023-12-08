{{ config(materialized = 'table',) }}

WITH settlements AS (
    SELECT *
    FROM {{ ref('fct_payments_settlements') }}
),

-- TODO: decide whether refunds should be joined in as part of the creation of this table?
-- mapping refunds to settlements may require using settlement_id, which is not available downstream of this model

summarize_by_type AS (
    SELECT
        participant_id,
        aggregation_id,
        retrieval_reference_number,
        settlement_type,
        LOGICAL_OR(imputed_type) AS type_contains_imputed_type,
        MAX(record_updated_timestamp_utc) AS type_latest_update_timestamp,
        SUM(transaction_amount) AS total_amount,
        LOGICAL_AND(settlement_status = "SETTLED") AS is_settled
    FROM settlements
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
        COUNTIF(settlement_type = "CREDIT") > 0 AS contains_refund,
        LOGICAL_AND(is_settled) AS is_settled
    FROM summarize_by_type
    GROUP BY 1, 2, 3
),

int_payments__settlements_to_aggregations AS (
    SELECT
        summary.participant_id,
        summary.aggregation_id,
        summary.retrieval_reference_number,
        contains_imputed_type,
        latest_update_timestamp,
        net_amount AS net_settled_amount_dollars,
        contains_refund,
        summary.is_settled AS aggregation_is_settled,
        COALESCE(debit.total_amount,0) AS debit_amount,
        debit.is_settled AS debit_is_settled,
        COALESCE(credit.total_amount,0) AS credit_amount,
        credit.is_settled AS credit_is_settled
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

SELECT * FROM int_payments__settlements_to_aggregations
