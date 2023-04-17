{{ config(materialized='table') }}

WITH stg_elavon__transactions AS (
    SELECT *
    FROM {{ ref('stg_elavon__transactions') }}
),

remove_special_characters AS (
    SELECT

        * EXCEPT (fund_amt, batch_amt, amount, surchg_amount, convnce_amt, payment_date, transaction_date, settlement_date),

        CAST(REGEXP_REPLACE(fund_amt, r'\$|,', '') as NUMERIC) fund_amt,
        CAST(REGEXP_REPLACE(batch_amt, r'\$|,', '') as NUMERIC) batch_amt,
        CAST(REGEXP_REPLACE(amount, r'\$|,', '') as NUMERIC) amount,
        CAST(REGEXP_REPLACE(surchg_amount, r'\$|,', '') as NUMERIC) surchg_amount,
        CAST(REGEXP_REPLACE(convnce_amt, r'\$|,', '') as NUMERIC) convnce_amt,

        regexp_extract(payment_date, r'[^@\.]+') AS payment_date,
        regexp_extract(transaction_date, r'[^@\.]+') AS transaction_date,
        regexp_extract(settlement_date, r'[^@\.]+') AS settlement_date

    FROM {{ ref('stg_elavon__transactions') }}
),

fct_elavon__transactions AS (
    SELECT

        * EXCEPT (payment_date, transaction_date, settlement_date),

        CASE WHEN
            LENGTH(payment_date) < 8
            THEN PARSE_DATE('%m%d%Y',  CONCAT(0, payment_date))
        ELSE PARSE_DATE('%m%d%Y',  payment_date)
        END AS payment_date,

        CASE WHEN
            LENGTH(transaction_date) < 8
            THEN PARSE_DATE('%m%d%Y',  CONCAT(0, transaction_date))
        ELSE PARSE_DATE('%m%d%Y',  transaction_date)
        END AS transaction_date,

        CASE WHEN
            LENGTH(settlement_date) < 8
            THEN PARSE_DATE('%m%d%Y',  CONCAT(0, settlement_date))
        ELSE PARSE_DATE('%m%d%Y',  settlement_date)
        END AS settlement_date

    FROM remove_special_characters
)

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

FROM fct_elavon__transactions
