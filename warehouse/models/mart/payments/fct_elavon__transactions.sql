{{ config(materialized='table') }}

WITH

int_elavon__billing_transactions AS (
    SELECT * FROM {{ ref('int_elavon__billing_transactions') }}
),

int_elavon__deposit_transactions AS (
    SELECT * FROM {{ ref('int_elavon__deposit_transactions') }}
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

fct_elavon__transactions AS (

    SELECT

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

    FROM union_deposits_and_billing

)

SELECT * FROM fct_elavon__transactions
