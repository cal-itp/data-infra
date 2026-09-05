WITH settlements AS (
    SELECT * from {{ ref('fct_payments_settlements_enghouse') }}
),

summarize_by_type AS (
    SELECT
        operator_id,
        payment_reference,
        settlement_type,
        SUM(amount) AS total_amount,
        MAX(timestamp) AS type_latest_settlement_update_timestamp,
        COUNT(*) AS num_settlements_type
        -- TODO: does fct_payments_settlements carry a settlement status, or do we just get that from pay_windows? not answering for now to get mvp
        -- TODO: summarize operation here
    FROM settlements
    GROUP BY payment_reference, operator_id, settlement_type -- the only key we have to link pay_windows and transactions is payment_reference, which is also the join from Enghouse to Elavon
),

summarize_overall AS (
    SELECT
        operator_id,
        payment_reference,
        MAX(type_latest_settlement_update_timestamp) AS latest_settlement_update_timestamp,
        SUM(num_settlements_type) AS num_settlements,
        SUM(total_amount) AS net_amount,
        COUNTIF(settlement_type = "CREDIT") > 0 AS contains_refund
    FROM summarize_by_type
    GROUP BY operator_id, payment_reference
), -- TODO - we can't determine duplicate payment_reference values here - is there any validation checking like that we need to consider here?

int_payments__settlements_to_aggregations_enghouse AS (
    SELECT
        summary.operator_id,
        summary.payment_reference,
        summary.latest_settlement_update_timestamp,
        summary.num_settlements,
        summary.net_amount AS net_settlement_amount_dollars,
        summary.contains_refund,
        COALESCE(debit.num_settlements_type, 0) AS num_debit_settlements,
        COALESCE(credit.num_settlements_type, 0) AS num_credit_settlements,
        COALESCE(debit.total_amount,0) AS debit_amount,
        COALESCE(credit.total_amount,0) AS credit_amount
    FROM summarize_overall AS summary
    LEFT JOIN summarize_by_type AS debit
        ON summary.payment_reference = debit.payment_reference
        AND summary.operator_id = debit.operator_id
        AND debit.settlement_type = "DEBIT"
    LEFT JOIN summarize_by_type AS credit
        on summary.payment_reference = credit.payment_reference
        AND summary.operator_id = credit.operator_id
        AND credit.settlement_type = "CREDIT"
)

SELECT
    operator_id,
    payment_reference,
    latest_settlement_update_timestamp,
    num_settlements,
    net_settlement_amount_dollars,
    contains_refund,
    num_debit_settlements,
    num_credit_settlements,
    debit_amount,
    credit_amount
FROM int_payments__settlements_to_aggregations_enghouse
