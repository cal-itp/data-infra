WITH stg_cleaned_micropayment_device_transactions AS (

    SELECT * FROM {{ ref('stg_cleaned_micropayment_device_transactions') }}
),

stg_cleaned_micropayments AS (

    SELECT * FROM {{ ref('stg_cleaned_micropayments') }}
),

debited_micropayments AS (

    SELECT * FROM {{ ref('debited_micropayments') }}
),

refunded_micropayments AS (

    SELECT
        m_debit.micropayment_id,
        m_credit.charge_amount AS refund_amount
    FROM debited_micropayments AS m_debit
    INNER JOIN stg_cleaned_micropayment_device_transactions USING (micropayment_id)
    INNER JOIN stg_cleaned_micropayment_device_transactions AS dt_credit USING (littlepay_transaction_id)
    INNER JOIN stg_cleaned_micropayments AS m_credit ON
        dt_credit.micropayment_id = m_credit.micropayment_id
    WHERE m_credit.type = 'CREDIT'
        AND m_credit.charge_type = 'refund'

)

SELECT * FROM refunded_micropayments
