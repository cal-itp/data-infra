WITH source AS (
    SELECT * FROM {{ littlepay_source('external_littlepay', 'micropayment_device_transactions') }}
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
        -- could this be a distinct?
        PARTITION BY littlepay_transaction_id, micropayment_id
        ORDER BY littlepay_export_ts DESC
    ) = 1
)

SELECT * FROM stg_littlepay__micropayment_device_transactions
