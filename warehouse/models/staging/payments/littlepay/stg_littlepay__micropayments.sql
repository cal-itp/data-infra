WITH source AS (
    SELECT * FROM {{ littlepay_source('external_littlepay', 'micropayments') }}
),

stg_littlepay__micropayments AS (
    SELECT
        {{ trim_make_empty_string_null('micropayment_id') }} AS micropayment_id,
        {{ trim_make_empty_string_null('aggregation_id') }} AS aggregation_id,
        {{ trim_make_empty_string_null('participant_id') }} AS participant_id,
        {{ trim_make_empty_string_null('customer_id') }} AS customer_id,
        {{ trim_make_empty_string_null('funding_source_vault_id') }} AS funding_source_vault_id,
        TIMESTAMP(transaction_time) AS transaction_time,
        {{ trim_make_empty_string_null('payment_liability') }} AS payment_liability,
        SAFE_CAST(charge_amount AS NUMERIC) AS charge_amount,
        SAFE_CAST(nominal_amount AS NUMERIC) AS nominal_amount,
        {{ trim_make_empty_string_null('currency_code') }} AS currency_code,
        {{ trim_make_empty_string_null('type') }} AS type,
        {{ trim_make_empty_string_null('charge_type') }} AS charge_type,
        _line_number,
        `instance`,
        extract_filename,
        ts,
        littlepay_export_ts,
    FROM source
    QUALIFY ROW_NUMBER() OVER (PARTITION BY micropayment_id ORDER BY littlepay_export_ts DESC, transaction_time DESC) = 1
)

SELECT * FROM stg_littlepay__micropayments
