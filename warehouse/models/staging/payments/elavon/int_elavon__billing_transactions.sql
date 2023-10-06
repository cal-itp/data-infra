{{ config(materialized='table') }}

WITH

billing_transactions AS (

  SELECT * FROM {{ ref('stg_elavon__transactions') }}
  WHERE batch_type = 'B'

),

dedup_billing_transactions AS (

  SELECT *
  FROM billing_transactions
  QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1

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
      customer_name,
      merchant_number,
      external_mid,
      chain,
      batch_amt,
      amount,
      card_type,
      charge_type,
      charge_type_description,
      card_plan,
      settlement_method,
      currency_code,
      ent_num,
      dt,
      execution_ts

  FROM dedup_billing_transactions

)

SELECT * FROM int_elavon__billing_transactions
