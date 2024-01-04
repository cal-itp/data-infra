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

payments_entity_mapping AS (
    SELECT
        * EXCEPT(littlepay_participant_id),
        littlepay_participant_id AS participant_id
    FROM {{ ref('payments_entity_mapping') }}
),

orgs AS (
    SELECT * FROM {{ ref('dim_organizations') }}
),

-- TODO: add refunds

join_payments AS (
    SELECT
        COALESCE(micropayments.aggregation_id, authorisations.aggregation_id, settlements.aggregation_id) AS aggregation_id,
        COALESCE(micropayments.participant_id, authorisations.participant_id, settlements.participant_id) AS participant_id,
        COALESCE(latest_update_timestamp, authorisation_date_time_utc, latest_transaction_time) AS aggregation_datetime,
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

join_orgs AS (
    SELECT
        join_payments.*,
        orgs.name AS organization_name,
        orgs.source_record_id AS organization_source_record_id,
    FROM join_payments
    LEFT JOIN payments_entity_mapping USING (participant_id)
    LEFT JOIN orgs
        ON payments_entity_mapping.organization_source_record_id = orgs.source_record_id
        AND CAST(join_payments.aggregation_datetime AS TIMESTAMP) BETWEEN orgs._valid_from AND orgs._valid_to
),

fct_payments_aggregations AS (
    SELECT
        participant_id,
        organization_name,
        organization_source_record_id,
        LAST_DAY(EXTRACT(DATE FROM aggregation_datetime AT TIME ZONE "America/Los_Angeles"), MONTH) AS end_of_month_date,
        LAST_DAY(EXTRACT(DATE FROM aggregation_datetime), MONTH) AS end_of_month_date_utc,
        aggregation_id,
        has_micropayment,
        has_authorisation,
        has_settlement,
        aggregation_datetime,
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
        final_authorisation_has_null_status,
        authorisation_date_time_utc AS latest_authorisation_update_datetime,
        contains_imputed_type AS settlement_contains_imputed_type,
        latest_update_timestamp AS latest_settlement_update_datetime,
        net_settled_amount_dollars,
        contains_refund AS settlement_contains_refund,
        debit_amount AS settlement_debit_amount,
        credit_amount AS settlement_credit_amount,
        aggregation_is_settled,
        debit_is_settled,
        credit_is_settled
    FROM join_orgs
)

SELECT * FROM fct_payments_aggregations
