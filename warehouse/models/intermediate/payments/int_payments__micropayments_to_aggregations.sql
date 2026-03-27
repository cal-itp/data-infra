{{
  config(
    materialized = 'table',
    )
}}

WITH micropayments AS (
    SELECT *
    FROM {{ ref('int_littlepay__unioned_micropayments') }}
),

customer_mapping AS (
    SELECT *
    FROM {{ ref('int_payments__customers') }}
),

customer_funding_sources AS (
    SELECT *
    FROM {{ ref('int_payments__customer_funding_source_vaults') }}
),

-- flag micropayments that were adjusted
micropayment_adj AS (
    SELECT DISTINCT micropayment_id
    FROM {{ ref('int_littlepay__unioned_micropayment_adjustments') }}
    WHERE applied
),

int_payments__micropayments_to_aggregations AS (
    SELECT
        micropayments.participant_id,
        micropayments.aggregation_id,
        --customer_mapping.customer_id,
        customer_mapping.principal_customer_id,
        customer_funding_sources.card_scheme,
        customer_funding_sources.bin,
        SUM(micropayments.charge_amount) AS net_micropayment_amount_dollars,
        SUM(COALESCE(micropayments.nominal_amount,0)) AS total_nominal_amount_dollars,
        MAX(micropayments.transaction_time) AS latest_transaction_time,
        COUNT(DISTINCT micropayments.micropayment_id) AS num_micropayments,
        LOGICAL_OR(micropayments.charge_type = "refund") AS contains_pre_settlement_refund,
        LOGICAL_OR(micropayments.charge_type LIKE "%variable%") AS contains_variable_fare,
        LOGICAL_OR(micropayments.charge_type = "flat_fare") AS contains_flat_fare,
        LOGICAL_OR(micropayments.charge_type LIKE "%pending%") AS contains_pending_charge,
        LOGICAL_OR(micropayment_adj.micropayment_id IS NOT NULL) AS contains_adjusted_micropayment
    FROM micropayments
    LEFT JOIN micropayment_adj
        ON micropayments.micropayment_id = micropayment_adj.micropayment_id
    LEFT JOIN customer_mapping
        ON micropayments.customer_id = customer_mapping.customer_id
        AND micropayments.participant_id = customer_mapping.participant_id
    LEFT JOIN customer_funding_sources
        ON micropayments.funding_source_vault_id = customer_funding_sources.funding_source_vault_id
        AND micropayments.participant_id = customer_funding_sources.participant_id
        AND micropayments.transaction_time >= customer_funding_sources.calitp_valid_at
        AND micropayments.transaction_time < customer_funding_sources.calitp_invalid_at
    GROUP BY 1, 2, 3, 4, 5--, 6
)

SELECT * FROM int_payments__micropayments_to_aggregations
