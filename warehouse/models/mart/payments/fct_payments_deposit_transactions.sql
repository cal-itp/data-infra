WITH deposits AS ( -- noqa: ST03
    SELECT *
    FROM {{ ref('int_elavon__deposit_transactions') }}
),

label AS (
    {{ label_elavon_entities(input_model = 'deposits') }}
),

fct_payments_deposit_transactions AS (
    SELECT
        LAST_DAY(payment_date, MONTH) AS end_of_month_date,
        organization_name,
        organization_source_record_id,
        littlepay_participant_id,
        payment_reference,
        payment_date,
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
        card_type,
        charge_type,
        charge_type_description,
        card_plan,
        transaction_date,
        settlement_date,
        authorization_code,
        roc_text,
        trn_aci,
        card_scheme_ref,
        trn_ref_num,
        settlement_method,
        currency_code,
        mer_ref,
        purch_id,
        cust_cod,
        trn_arn,
        term_id,
        ent_num,
        dt,
        execution_ts
    FROM label
)

SELECT * FROM fct_payments_deposit_transactions
