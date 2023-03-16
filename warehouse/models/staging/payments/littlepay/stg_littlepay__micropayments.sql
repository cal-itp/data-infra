WITH source AS (
    SELECT * FROM {{ source('external_littlepay', 'micropayments') }}
),

stg_littlepay__micropayments AS (
    SELECT
        micropayment_id,
        aggregation_id,
        participant_id,
        customer_id,
        funding_source_vault_id,
        transaction_time,
        payment_liability,
        charge_amount,
        nominal_amount,
        currency_code,
        type,
        charge_type,
        _line_number,
        `instance`,
        extract_filename,
        ts,
    FROM source
)

SELECT * FROM stg_littlepay__micropayments
