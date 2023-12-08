{{ config(materialized='table') }}

WITH

source AS (
    SELECT * FROM {{ source('elavon_external_tables', 'transactions') }}
),

get_latest_extract AS(

    SELECT *
    FROM source
    -- we pull the whole world every day in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1

),

handle_strings_and_remove_special_characters AS (

    SELECT

        {{ trim_make_empty_string_null('payment_reference') }} AS payment_reference,
        REGEXP_EXTRACT({{ trim_make_empty_string_null('payment_date') }}, r'[^@\.]+') AS payment_date,
        {{ trim_make_empty_string_null('account_number') }} AS account_number,
        {{ trim_make_empty_string_null('routing_number') }} AS routing_number,
        CAST(REGEXP_REPLACE({{ trim_make_empty_string_null('fund_amt') }}, r'\$|,', '') as NUMERIC) AS fund_amt,
        {{ trim_make_empty_string_null('batch_reference') }} AS batch_reference,
        {{ trim_make_empty_string_null('batch_type') }} AS batch_type,
        {{ trim_make_empty_string_null('customer_batch_reference') }} AS customer_batch_reference,
        {{ trim_make_empty_string_null('customer_name') }} AS customer_name,
        {{ trim_make_empty_string_null('merchant_number') }} AS merchant_number,
        {{ trim_make_empty_string_null('external_mid') }} AS external_mid,
        {{ trim_make_empty_string_null('store_number') }} AS store_number,
        {{ trim_make_empty_string_null('chain') }} AS chain,
        CAST(REGEXP_REPLACE({{ trim_make_empty_string_null('batch_amt') }}, r'\$|,', '') as NUMERIC) AS batch_amt,
        CAST(REGEXP_REPLACE({{ trim_make_empty_string_null('amount') }}, r'\$|,', '') as NUMERIC) AS amount,
        CAST(REGEXP_REPLACE({{ trim_make_empty_string_null('surchg_amount') }}, r'\$|,', '') as NUMERIC) AS surchg_amount,
        CAST(REGEXP_REPLACE({{ trim_make_empty_string_null('convnce_amt') }}, r'\$|,', '') as NUMERIC) AS convnce_amt,
        {{ trim_make_empty_string_null('card_type') }} AS card_type,
        {{ trim_make_empty_string_null('charge_type') }} AS charge_type,
        {{ trim_make_empty_string_null('charge_type_description') }} AS charge_type_description,
        {{ trim_make_empty_string_null('card_plan') }} AS card_plan,
        {{ trim_make_empty_string_null('card_no') }} AS card_no,
        {{ trim_make_empty_string_null('chk_num') }} AS chk_num,
        REGEXP_EXTRACT({{ trim_make_empty_string_null('transaction_date') }}, r'[^@\.]+') AS transaction_date,
        REGEXP_EXTRACT({{ trim_make_empty_string_null('settlement_date') }}, r'[^@\.]+') AS settlement_date,
        {{ trim_make_empty_string_null('authorization_code') }} AS authorization_code,
        {{ trim_make_empty_string_null('chargeback_control_no') }} AS chargeback_control_no,
        {{ trim_make_empty_string_null('roc_text') }} AS roc_text,
        {{ trim_make_empty_string_null('trn_aci') }} AS trn_aci,
        {{ trim_make_empty_string_null('card_scheme_ref') }} AS card_scheme_ref,
        {{ trim_make_empty_string_null('trn_ref_num') }} AS trn_ref_num,
        {{ trim_make_empty_string_null('settlement_method') }} AS settlement_method,
        {{ trim_make_empty_string_null('currency_code') }} AS currency_code,
        {{ trim_make_empty_string_null('cb_acq_ref_id') }} AS cb_acq_ref_id,
        {{ trim_make_empty_string_null('chgbk_rsn_code') }} AS chgbk_rsn_code,
        {{ trim_make_empty_string_null('chgbk_rsn_desc') }} AS chgbk_rsn_desc,
        {{ trim_make_empty_string_null('mer_ref') }} AS mer_ref,
        {{ trim_make_empty_string_null('purch_id') }} AS purch_id,
        {{ trim_make_empty_string_null('cust_cod') }} AS cust_cod,
        {{ trim_make_empty_string_null('trn_arn') }} AS trn_arn,
        {{ trim_make_empty_string_null('term_id') }} AS term_id,
        {{ trim_make_empty_string_null('ent_num') }} AS ent_num,
        dt,
        execution_ts

    FROM get_latest_extract

),

format_dates AS (

    SELECT

        * EXCEPT (payment_date, transaction_date, settlement_date),

        {{ parse_elavon_date('payment_date') }} AS payment_date,
        {{ parse_elavon_date('transaction_date') }} AS transaction_date,
        {{ parse_elavon_date('settlement_date') }} AS settlement_date,

    FROM handle_strings_and_remove_special_characters

),



stg_elavon__transactions AS (

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

    FROM format_dates

)

SELECT * FROM stg_elavon__transactions
