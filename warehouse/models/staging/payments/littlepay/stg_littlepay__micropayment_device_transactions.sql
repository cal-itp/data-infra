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
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY littlepay_transaction_id, micropayment_id, ts
        ORDER BY ts DESC
    ) = 1
)

SELECT * FROM stg_littlepay__micropayment_device_transactions
