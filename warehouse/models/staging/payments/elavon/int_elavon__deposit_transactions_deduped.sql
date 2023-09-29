{{ config(materialized='table') }}

WITH

stg_elavon__transactions AS (

  SELECT * FROM {{ ref('stg_elavon__transactions') }}

),

deposit_transactions AS (

  SELECT * FROM stg_elavon__transactions
  WHERE batch_type = 'D'

),

dedup_deposit_transactions AS (

  SELECT

      transactions.*

  FROM deposit_transactions AS transactions

  INNER JOIN

  (SELECT trn_ref_num, MAX(execution_ts) AS max_ts FROM deposit_transactions GROUP BY trn_ref_num) AS grouped_tbl
      ON transactions.trn_ref_num = grouped_tbl.trn_ref_num
          AND transactions.execution_ts = max_ts
),

int_elavon__deposit_transactions_deduped AS (

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

    FROM dedup_deposit_transactions

)

SELECT * FROM int_elavon__deposit_transactions_deduped
