WITH source AS (
    SELECT
      transactions.payment_reference,
      transactions.payment_date,
      transactions.account_number,
      transactions.routing_number,
      transactions.fund_amt,
      transactions.batch_reference,
      transactions.batch_type,
      transactions.customer_batch_reference,
      transactions.customer_name,
      transactions.merchant_number,
      transactions.external_mid,
      transactions.store_number,
      transactions.chain,
      transactions.batch_amt,
      transactions.amount,
      transactions.surchg_amount,
      transactions.convnce_amt,
      transactions.card_type,
      transactions.charge_type,
      transactions.charge_type_description,
      transactions.card_plan,
      transactions.card_no,
      transactions.chk_num,
      transactions.transaction_date,
      transactions.settlement_date,
      transactions.authorization_code,
      transactions.chargeback_control_no,
      transactions.roc_text,
      transactions.trn_aci,
      transactions.card_scheme_ref,
      transactions.trn_ref_num,
      transactions.settlement_method,
      transactions.currency_code,
      transactions.cb_acq_ref_id,
      transactions.chgbk_rsn_code,
      transactions.chgbk_rsn_desc,
      transactions.mer_ref,
      transactions.purch_id,
      transactions.cust_cod,
      transactions.trn_arn,
      transactions.term_id,
      transactions.ent_num,
      transactions.dt,
      transactions.execution_ts
    FROM {{ source('elavon_external_tables', 'transactions') }}
  INNER JOIN (
    SELECT trn_ref_num, MAX(execution_ts) AS max_ts FROM {{ source('elavon_external_tables', 'transactions') }} GROUP BY trn_ref_num
  ) grouped_tbl ON transactions.trn_ref_num = grouped_tbl.trn_ref_num AND transactions.execution_ts = max_ts
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
    FROM source
)

SELECT * FROM stg_elavon__transactions