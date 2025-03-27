{{
  config(
    materialized = 'table',
    )
}}

WITH micropayments AS (
    SELECT *
    FROM {{ ref('int_littlepay__unioned_micropayments') }}
),

-- flag micropayments that were adjusted
micropayment_adj AS (
    SELECT DISTINCT micropayment_id
    FROM {{ ref('int_littlepay__unioned_micropayment_adjustments') }}
    WHERE applied
),

int_payments__micropayments_to_aggregations AS (
    SELECT
        participant_id,
        aggregation_id,
        SUM(charge_amount) AS net_micropayment_amount_dollars,
        SUM(COALESCE(nominal_amount,0)) AS total_nominal_amount_dollars,
        MAX(transaction_time) AS latest_transaction_time,
        COUNT(DISTINCT micropayment_id) AS num_micropayments,
        LOGICAL_OR(charge_type = "refund") AS contains_pre_settlement_refund,
        LOGICAL_OR(charge_type LIKE "%variable%") AS contains_variable_fare,
        LOGICAL_OR(charge_type = "flat_fare") AS contains_flat_fare,
        LOGICAL_OR(charge_type LIKE "%pending%") AS contains_pending_charge,
        LOGICAL_OR(micropayment_adj.micropayment_id IS NOT NULL) AS contains_adjusted_micropayment
    FROM micropayments
    LEFT JOIN micropayment_adj USING (micropayment_id)
    GROUP BY 1, 2
)

SELECT * FROM int_payments__micropayments_to_aggregations
