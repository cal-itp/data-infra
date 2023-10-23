{{
  config(
    materialized = 'table',
    post_hook="{{ payments_row_access_policy() }}"
    )
}}

WITH micropayments AS (
    SELECT *
    FROM {{ ref('int_payments__micropayments_to_aggregations') }}
),

authorisations AS (
    SELECT *
    FROM {{ ref('int_payments__latest_authorisations_by_aggregation') }}
),

settlements AS (
    SELECT *
    FROM {{ ref('int_payments__settlements_to_aggregations') }}
),

-- TODO: add refunds

joined AS (
    SELECT
        COALESCE(micropayments.aggregation_id, authorisations.aggregation_id, settlements.aggregation_id) AS aggregation_id,
        COALESCE(micropayments.participant_id, authorisations.participant_id, settlements.participant_id) AS participant_id,
        micropayments.aggregation_id IS NOT NULL AS has_micropayment,
        authorisations.aggregation_id IS NOT NULL AS has_authorisation,
        settlements.aggregation_id IS NOT NULL AS has_settlement,
        micropayments.* EXCEPT(aggregation_id, participant_id),
        authorisations.* EXCEPT(aggregation_id, participant_id, retrieval_reference_number),
        settlements.* EXCEPT(aggregation_id, participant_id, retrieval_reference_number),
        authorisations.retrieval_reference_number AS authorisation_retrieval_reference_number,
        settlements.retrieval_reference_number AS settlement_retrieval_reference_number
    FROM micropayments
    FULL OUTER JOIN authorisations USING (aggregation_id)
    FULL OUTER JOIN settlements USING (aggregation_id)
),

fct_payments_aggregations AS (
    SELECT
        participant_id,
        aggregation_id,
        has_micropayment,
        has_authorisation,
        has_settlement,
        authorisation_retrieval_reference_number,
        settlement_retrieval_reference_number,
        net_micropayment_amount_dollars,
        total_nominal_amount_dollars AS total_micropayment_nominal_amount_dollars,
        latest_transaction_time AS latest_micropayment_transaction_datetime,
        num_micropayments,
        contains_pre_settlement_refund,
        contains_variable_fare,
        contains_flat_fare,
        contains_pending_charge,
        contains_adjusted_micropayment,
        request_type AS latest_authorisation_request_type,
        transaction_amount AS authorisation_transaction_amount,
        status AS latest_authorisation_status,
        authorisation_date_time_utc AS latest_authorisation_update_datetime,
        contains_imputed_type AS settlement_contains_imputed_type,
        latest_update_timestamp AS latest_settlement_update_datetime,
        net_settled_amount_dollars,
        contains_refund AS settlement_contains_refund,
        debit_amount AS settlement_debit_amount,
        credit_amount AS settlement_credit_amount
    FROM joined
)

SELECT * FROM fct_payments_aggregations
