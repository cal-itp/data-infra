WITH source AS (
    SELECT * FROM {{ littlepay_source('external_littlepay', 'micropayments') }}
),

stg_littlepay__micropayments AS (
    SELECT
        micropayment_id,
        aggregation_id,
        participant_id,
        customer_id,
        funding_source_vault_id,
        TIMESTAMP(transaction_time) AS transaction_time,
        payment_liability,
        SAFE_CAST(charge_amount AS FLOAT64) AS charge_amount,
        SAFE_CAST(nominal_amount AS FLOAT64) AS nominal_amount,
        currency_code,
        type,
        charge_type,
        _line_number,
        `instance`,
        extract_filename,
        ts,
        littlepay_export_ts,
    FROM source
    QUALIFY ROW_NUMBER() OVER (PARTITION BY micropayment_id ORDER BY littlepay_export_ts DESC, transaction_time DESC) = 1
)

SELECT * FROM stg_littlepay__micropayments
