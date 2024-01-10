{{ config(materialized='table') }}

WITH

int_elavon__billing_transactions AS (
    SELECT * FROM {{ ref('int_elavon__billing_transactions') }}
),

int_elavon__deposit_transactions AS (
    SELECT * FROM {{ ref('int_elavon__deposit_transactions') }}
),

payments_entity_mapping AS (
    SELECT
        * EXCEPT(elavon_customer_name),
        elavon_customer_name AS customer_name
    FROM {{ ref('payments_entity_mapping') }}
),

orgs AS (
    SELECT * FROM {{ ref('dim_organizations') }}
),

union_deposits_and_billing AS (

    SELECT
        *
    FROM int_elavon__billing_transactions
    UNION ALL
    SELECT
        *
    FROM int_elavon__deposit_transactions

),

join_orgs AS (
    SELECT
        union_deposits_and_billing.*,
        orgs.name AS organization_name,
        orgs.source_record_id AS organization_source_record_id,
        littlepay_participant_id
    FROM union_deposits_and_billing
    LEFT JOIN payments_entity_mapping USING (customer_name)
    LEFT JOIN orgs
        ON payments_entity_mapping.organization_source_record_id = orgs.source_record_id
        AND CAST(union_deposits_and_billing.payment_date AS TIMESTAMP) BETWEEN orgs._valid_from AND orgs._valid_to
),

fct_elavon__transactions AS (

    SELECT
        organization_name,
        organization_source_record_id,
        littlepay_participant_id,
        LAST_DAY(payment_date, MONTH) AS end_of_month_date,
        payment_reference,
        payment_date,
        account_number,
        routing_number,
        fund_amt,
        batch_reference,
        batch_type,
        customer_batch_reference,
        customer_name,
        merchant_number,
        external_mid,
        store_number,
        chain,
        batch_amt,
        amount,
        surchg_amount,
        convnce_amt,
        card_type,
        charge_type,
        charge_type_description,
        card_plan,
        card_no,
        chk_num,
        transaction_date,
        settlement_date,
        authorization_code,
        chargeback_control_no,
        roc_text,
        trn_aci,
        card_scheme_ref,
        trn_ref_num,
        settlement_method,
        currency_code,
        cb_acq_ref_id,
        chgbk_rsn_code,
        chgbk_rsn_desc,
        mer_ref,
        purch_id,
        cust_cod,
        trn_arn,
        term_id,
        ent_num,
        dt,
        execution_ts

    FROM join_orgs

)

SELECT * FROM fct_elavon__transactions
