WITH chargebacks AS ( -- noqa: ST03
    SELECT *
    FROM {{ ref('stg_elavon__transactions') }}
    WHERE batch_type = "C"
),

label AS (
    {{ label_elavon_entities(input_model = 'chargebacks') }}
),

fct_payments_chargeback_transactions AS (
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
        customer_name,
        merchant_number,
        external_mid,
        chargeback_control_no,
        roc_text,
        cb_acq_ref_id,
        chgbk_rsn_code,
        chgbk_rsn_desc,
        chain,
        batch_amt,
        amount,
        card_type,
        charge_type,
        charge_type_description,
        card_plan,
        transaction_date,
        trn_aci,
        card_scheme_ref,
        trn_ref_num,
        settlement_method,
        currency_code,
        trn_arn,
        ent_num,
        dt,
        execution_ts
    FROM label
)

SELECT * FROM fct_payments_chargeback_transactions
