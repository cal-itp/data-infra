WITH billing AS ( -- noqa: ST03
    SELECT *
    FROM {{ ref('int_elavon__billing_transactions') }}
),

label AS (
    {{ label_elavon_entities(input_model = 'billing') }}
),

fct_payments_billing_transactions AS (
    SELECT
        payment_reference,
        payment_date,
        LAST_DAY(payment_date, MONTH) AS end_of_month_date,
        organization_name,
        organization_source_record_id,
        littlepay_participant_id,
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
    FROM label
)

SELECT * FROM fct_payments_billing_transactions
