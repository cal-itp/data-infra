WITH debited_micropayments AS (

    SELECT * FROM {{ ref('debited_micropayments') }}

),

refunded_micropayments AS (

    SELECT * FROM {{ ref('refunded_micropayments') }}

),

joined_debited_micropayments_refunded_micropayments AS (

    SELECT
        m.participant_id,
        m.micropayment_id,
        m.transaction_time,

        -- Customer and funding source information
        m.funding_source_vault_id,
        m.customer_id,
        m.charge_amount,
        mr.refund_amount,
        m.nominal_amount,
        m.charge_type

    FROM debited_micropayments AS m
    LEFT JOIN refunded_micropayments AS mr USING (micropayment_id)

)

SELECT * FROM joined_debited_micropayments_refunded_micropayments
