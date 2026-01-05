WITH debit_micropayments AS (
    SELECT * FROM {{ ref('int_littlepay__unioned_micropayments') }}
    WHERE type = 'DEBIT'
),

-- micropayments that don't appear in the cleaned table are subject to issue #647
-- they are pending payments that incorrectly had a different micropayment ID created from their associated completed payment
valid_micropayment_ids AS (
    SELECT DISTINCT micropayment_id
    FROM {{ ref('int_payments__cleaned_micropayment_device_transactions') }}
),

adjustments AS (
    SELECT * FROM {{ ref('int_littlepay__unioned_micropayment_adjustments') }}
    -- we only want adjustments that were actually applied
    WHERE applied
),

products AS (
    SELECT * FROM {{ ref('int_littlepay__unioned_product_data') }}
),

individual_refunds AS (
    SELECT * FROM {{ ref('int_payments__refunds_deduped') }}
),

aggregation_refunds AS (
    SELECT * FROM {{ ref('int_payments__refunds_to_aggregations') }}
),

micropayments_per_aggregation AS (
    SELECT
        participant_id,
        aggregation_id,
        COUNT(*) AS aggregation_micropayment_ct
    FROM debit_micropayments
    GROUP BY 1, 2
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
        -- there is a bug where some refunds' micropayment IDs don't map back correctly to their associated micropayment
        -- in those cases, if there's only one micropayment in the aggregation, we can impute that the aggregation refund applies just to the one micropayment
        CASE
            WHEN micropayments_per_aggregation.aggregation_micropayment_ct = 1
                AND individual_refunds.refund_amount IS NULL
                    THEN aggregation_refunds.total_refund_activity_amount_dollars
            ELSE individual_refunds.refund_amount
        END AS micropayment_refund_amount,
        aggregation_refunds.total_refund_activity_amount_dollars AS aggregation_refund_amount
    FROM debit_micropayments
    INNER JOIN valid_micropayment_ids USING (micropayment_id)
    LEFT JOIN adjustments USING (participant_id, micropayment_id)
    LEFT JOIN products USING (participant_id, product_id)
    LEFT JOIN individual_refunds USING (participant_id, micropayment_id, aggregation_id)
    LEFT JOIN aggregation_refunds USING (participant_id, aggregation_id)
    LEFT JOIN micropayments_per_aggregation USING (participant_id, aggregation_id)
)

SELECT * FROM int_payments__micropayments_adjustments_refunds_joined
