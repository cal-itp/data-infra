WITH debit_micropayments AS (
    SELECT * FROM {{ ref('stg_littlepay__micropayments') }}
    WHERE type = 'DEBIT'
),

adjustments AS (
    SELECT * FROM {{ ref('stg_littlepay__micropayment_adjustments') }}
    -- we only want adjustments that were actually applied
    WHERE applied
),

products AS (
    SELECT * FROM {{ ref('stg_littlepay__product_data') }}
),

individual_refunds AS (
    SELECT * FROM {{ ref('int_payments__refunds_deduped') }}
),

aggregation_refunds AS (
    SELECT * FROM {{ ref('int_payments__refunds_to_aggregations') }}
),

int_payments__micropayments_adjustments_refunds_joined AS (
    SELECT
        debit_micropayments.participant_id,
        debit_micropayments.micropayment_id,
        debit_micropayments.aggregation_id,
        debit_micropayments.funding_source_vault_id,
        debit_micropayments.customer_id,
        debit_micropayments.charge_amount,
        debit_micropayments.nominal_amount,
        debit_micropayments.charge_type,
        debit_micropayments.transaction_time,
        adjustments.adjustment_id,
        adjustments.type AS adjustment_type,
        adjustments.time_period_type AS adjustment_time_period_type,
        adjustments.description AS adjustment_description,
        adjustments.amount AS adjustment_amount,
        products.product_id,
        products.product_code,
        products.product_description,
        products.product_type,
        -- refund amount is a confusing name because our use of it here is directly opposite how LP uses it in their schema
        individual_refunds.proposed_amount AS micropayment_refund_amount,
        aggregation_refunds.total_refund_activity_amount_dollars AS aggregation_refund_amount
    FROM debit_micropayments
    LEFT JOIN adjustments USING (participant_id, micropayment_id)
    LEFT JOIN products USING (participant_id, product_id)
    LEFT JOIN individual_refunds USING (participant_id, micropayment_id, aggregation_id)
    LEFT JOIN aggregation_refunds USING (participant_id, aggregation_id)
)

SELECT * FROM int_payments__micropayments_adjustments_refunds_joined
