{{ config(materialized='table') }}

WITH

billing_transactions AS (

  SELECT * FROM {{ ref('stg_elavon__transactions') }}
  WHERE batch_type = 'B'

),

int_elavon__billing_transactions AS (

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

-- if we remove the need for a union between billing and deposit data downstream, these are the columns to keep
-- (ie deposit-specific, always null columns are removed)
      -- payment_reference,
      -- payment_date,
      -- account_number,
      -- routing_number,
      -- fund_amt,
      -- batch_reference,
      -- batch_type,
      -- customer_name,
      -- merchant_number,
      -- external_mid,
      -- chain,
      -- batch_amt,
      -- amount,
      -- card_type,
      -- charge_type,
      -- charge_type_description,
      -- card_plan,
      -- settlement_method,
      -- currency_code,
      -- ent_num,
      -- dt,
      -- execution_ts

  FROM billing_transactions

)

SELECT * FROM int_elavon__billing_transactions
