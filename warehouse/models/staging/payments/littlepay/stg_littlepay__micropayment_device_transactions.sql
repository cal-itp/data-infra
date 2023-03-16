WITH source AS (
    SELECT * FROM {{ source('external_littlepay', 'micropayment_device_transactions') }}
),

stg_littlepay__micropayment_device_transactions AS (
    SELECT
        littlepay_transaction_id,
        micropayment_id,
        _line_number,
        `instance`,
        extract_filename,
        ts,
    FROM source
)

SELECT * FROM stg_littlepay__micropayment_device_transactions
