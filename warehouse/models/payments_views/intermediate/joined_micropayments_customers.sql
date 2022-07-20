WITH joined_debited_micropayments_refunded_micropayments AS (

    SELECT * FROM {{ ref('joined_debited_micropayments_refunded_micropayments') }}
),

stg_cleaned_customers AS (

    SELECT * FROM {{ ref('stg_cleaned_customers') }}
),

stg_cleaned_customer_funding_source_vaults AS (

    SELECT * FROM {{ ref('stg_cleaned_customer_funding_source_vaults') }}
),

joined_micropayments_customers AS (

    SELECT
        m.participant_id,
        m.micropayment_id,
        m.transaction_time,

        -- Customer and funding source information
        m.funding_source_vault_id,
        m.customer_id,
        m.charge_amount,
        m.refund_amount,
        m.nominal_amount,
        m.charge_type,
        c.principal_customer_id,
        v.bin,
        v.masked_pan,
        v.card_scheme,
        v.issuer,
        v.issuer_country,
        v.form_factor
    FROM joined_debited_micropayments_refunded_micropayments AS m
    INNER JOIN stg_cleaned_customers AS c USING (customer_id)
    LEFT JOIN stg_cleaned_customer_funding_source_vaults AS v
        ON m.funding_source_vault_id = v.funding_source_vault_id
            AND m.transaction_time >= v.calitp_valid_at
            AND m.transaction_time < v.calitp_invalid_at

)

SELECT * FROM joined_micropayments_customers
