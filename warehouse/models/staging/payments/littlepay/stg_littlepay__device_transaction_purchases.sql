WITH source AS (
    SELECT * FROM {{ source('external_littlepay', 'device_transaction_purchases') }}
),

stg_littlepay__device_transaction_purchases AS (
    SELECT
        {{ trim_make_empty_string_null('littlepay_transaction_id') }} AS littlepay_transaction_id,
        {{ trim_make_empty_string_null('purchase_id') }} AS purchase_id,
        {{ trim_make_empty_string_null('correlated_purchase_id') }} AS correlated_purchase_id,
        {{ trim_make_empty_string_null('product_id') }} AS product_id,
        {{ trim_make_empty_string_null('description') }} AS description,
        {{ safe_cast('indicative_amount', type_numeric()) }} AS indicative_amount,
        {{ safe_cast('transaction_time', type_timestamp()) }} AS transaction_time,
        _line_number,
        `instance`,
        extract_filename,
        ts,
    FROM source
)

SELECT * FROM stg_littlepay__device_transaction_purchases
