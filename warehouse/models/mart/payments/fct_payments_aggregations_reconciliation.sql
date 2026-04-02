{{
  config(
    materialized = 'table',
    post_hook="{{ payments_littlepay_row_access_policy() }}"
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

customers AS (
    SELECT * FROM {{ ref('int_payments__customers_vaults_to_aggregations') }}
),

elavon_info AS (
  SELECT
    purch_id AS elavon_purch_id,
    MAX(settlement_date) AS elavon_settlement_date,
    MAX(payment_date) AS elavon_payment_date,
    SUM(amount) AS elavon_net_amount,
    SUM(CASE WHEN amount > 0 THEN amount ELSE 0 END) AS elavon_sales,
    SUM(CASE WHEN amount < 0 THEN amount ELSE 0 END) AS elavon_refunds,
  FROM
    {{ ref('fct_payments_deposit_transactions') }}
  WHERE COALESCE(purch_id, '') != ''
  GROUP BY
    purch_id
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
        settlements.retrieval_reference_number AS settlement_retrieval_reference_number,
        customers.principal_customer_id,
        customers.bin,
        customers.card_scheme
    FROM micropayments
    FULL OUTER JOIN authorisations USING (aggregation_id)
    FULL OUTER JOIN settlements USING (aggregation_id)
    LEFT JOIN customers USING (aggregation_id)
),

join_orgs AS (
    SELECT
        join_payments.*,
        orgs.name AS organization_name,
        orgs.source_record_id AS organization_source_record_id,
    FROM join_payments
    LEFT JOIN payments_entity_mapping
        ON join_payments.participant_id = payments_entity_mapping.participant_id
        AND CAST(join_payments.aggregation_datetime AS TIMESTAMP)
            BETWEEN CAST(payments_entity_mapping._in_use_from AS TIMESTAMP)
            AND CAST(payments_entity_mapping._in_use_until AS TIMESTAMP)
    LEFT JOIN orgs
        ON payments_entity_mapping.organization_source_record_id = orgs.source_record_id
        AND CAST(join_payments.aggregation_datetime AS TIMESTAMP) BETWEEN orgs._valid_from AND orgs._valid_to
),

fct_payments_aggregations AS (
    SELECT
        participant_id,
        organization_name,
        organization_source_record_id,
        LAST_DAY(EXTRACT(DATE FROM aggregation_datetime AT TIME ZONE "America/Los_Angeles"), MONTH) AS end_of_month_date_pacific,
        LAST_DAY(EXTRACT(DATE FROM aggregation_datetime), MONTH) AS end_of_month_date_utc,
        aggregation_id,
        principal_customer_id,
        elavon_purch_id,
        elavon_settlement_date,
        elavon_payment_date,
        elavon_net_amount,
        elavon_sales,
        elavon_refunds,
        bin,
        card_scheme,
        has_micropayment,
        has_authorisation,
        has_settlement,
        aggregation_datetime,
        authorisation_retrieval_reference_number,
        settlement_retrieval_reference_number,
        net_micropayment_amount_dollars,
        total_nominal_amount_dollars AS total_micropayment_nominal_amount_dollars,
        latest_transaction_time AS latest_micropayment_transaction_datetime,
        TIMESTAMP(DATETIME(latest_transaction_time, "America/Los_Angeles")) AS latest_micropayment_transaction_datetime_pacific,
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
        TIMESTAMP(DATETIME(latest_update_timestamp, "America/Los_Angeles")) AS latest_settlement_update_datetime_pacific,
        net_settled_amount_dollars,
        contains_refund AS settlement_contains_refund,
        debit_amount AS settlement_debit_amount,
        credit_amount AS settlement_credit_amount,
        debit_amount > 0 AS contains_nonzero_sales,
        aggregation_is_settled,
        debit_is_settled,
        credit_is_settled,
        CASE
            WHEN net_micropayment_amount_dollars = 0 THEN 'Zero-dollar value sales'
            WHEN net_micropayment_amount_dollars > 0 AND aggregation_is_settled AND elavon_purch_id IS NOT NULL THEN 'Settled non-zero sales (with Elavon match)'
            WHEN net_micropayment_amount_dollars > 0 AND aggregation_is_settled AND elavon_purch_id IS NULL THEN 'Settled non-zero sales (no Elavon match)'
            WHEN net_micropayment_amount_dollars > 0 AND (status IS NULL OR status NOT IN ('LOST','DECLINED','UNAVAILABLE','UNRECOVERABLE','INVALID')) AND (NOT aggregation_is_settled) THEN 'Unsettled non-zero sales'
            WHEN COALESCE(status,'') != '' AND status NOT IN ('AUTHORISED', 'VERIFIED') THEN 'Declined sales'
            ELSE 'UNKNOWN'
        END AS Reconciliation_Category
    FROM join_orgs
    LEFT JOIN elavon_info
        ON join_orgs.settlement_retrieval_reference_number = elavon_info.elavon_purch_id

)

SELECT * FROM fct_payments_aggregations
