WITH source AS (
    SELECT * FROM {{ source('external_littlepay', 'settlements') }}
),

stg_littlepay__settlements AS (
    SELECT
        {{ trim_make_empty_string_null('settlement_id') }} AS settlement_id,
        {{ trim_make_empty_string_null('participant_id') }} AS participant_id,
        {{ trim_make_empty_string_null('aggregation_id') }} AS aggregation_id,
        {{ trim_make_empty_string_null('customer_id') }} AS customer_id,
        {{ trim_make_empty_string_null('funding_source_id') }} AS funding_source_id,
        {{ safe_cast('transaction_amount', type_numeric()) }} AS transaction_amount,
        {{ trim_make_empty_string_null('retrieval_reference_number') }} AS retrieval_reference_number,
        {{ trim_make_empty_string_null('littlepay_reference_number') }} AS littlepay_reference_number,
        {{ trim_make_empty_string_null('external_reference_number') }} AS external_reference_number,
        {{ safe_cast('settlement_requested_date_time_utc', type_timestamp()) }} AS settlement_requested_date_time_utc,
        {{ trim_make_empty_string_null('acquirer') }} AS acquirer,
        _line_number,
        `instance`,
        extract_filename,
        ts,
    FROM source
)

SELECT * FROM stg_littlepay__settlements
