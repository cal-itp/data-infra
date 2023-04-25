WITH source AS (
    SELECT * FROM {{ source('external_littlepay', 'device_transaction_purchases') }}
),

stg_littlepay__device_transaction_purchases AS (
    SELECT
        littlepay_transaction_id,
        purchase_id,
        correlated_purchase_id,
        product_id,
        description,
        {{ safe_cast('indicative_amount', type_numeric()) }} AS indicative_amount,
        {{ safe_cast('transaction_time', type_timestamp()) }} AS transaction_time,
        _line_number,
        `instance`,
        extract_filename,
        ts,
    FROM source
)

SELECT * FROM stg_littlepay__device_transaction_purchases
