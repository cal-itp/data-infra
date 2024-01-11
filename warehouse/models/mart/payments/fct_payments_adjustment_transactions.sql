{{ config(materialized = 'table',
    post_hook="{{ payments_elavon_row_access_policy() }}") }}

WITH adjustments AS ( -- noqa: ST03
    SELECT *
    FROM {{ ref('stg_elavon__transactions') }}
    WHERE batch_type = "A"
),

label AS (
    {{ label_elavon_entities(input_model = 'adjustments') }}
),

fct_payments_adjustment_transactions AS (
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
        chain,
        batch_amt,
        amount,
        card_type,
        charge_type,
        charge_type_description,
        card_plan,
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

SELECT * FROM fct_payments_adjustment_transactions
