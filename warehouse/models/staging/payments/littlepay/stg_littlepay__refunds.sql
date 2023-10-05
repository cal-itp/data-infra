WITH source AS (
    SELECT * FROM {{ source('external_littlepay', 'refunds') }}
),

stg_littlepay__refunds AS (
    SELECT
        {{ trim_make_empty_string_null('refund_id') }} AS refund_id,
        {{ trim_make_empty_string_null('participant_id') }} AS participant_id,
        {{ trim_make_empty_string_null('customer_id') }} AS customer_id,
        {{ trim_make_empty_string_null('micropayment_id') }} AS micropayment_id,
        {{ trim_make_empty_string_null('aggregation_id') }} AS aggregation_id,
        {{ trim_make_empty_string_null('settlement_id') }} AS settlement_id,
        {{ trim_make_empty_string_null('retrieval_reference_number') }} AS retrieval_reference_number,
        {{ safe_cast('transaction_date', 'DATE') }} AS transaction_date,
        {{ safe_cast('transaction_amount', type_numeric()) }} AS transaction_amount,
        {{ safe_cast('proposed_amount', type_numeric()) }} AS proposed_amount,
        {{ safe_cast('refund_amount', type_numeric()) }} AS refund_amount,
        {{ safe_cast('currency_code', type_int()) }} AS currency_code,
        {{ trim_make_empty_string_null('status') }} AS status,
        {{ trim_make_empty_string_null('initiator') }} AS initiator,
        {{ trim_make_empty_string_null('reason') }} AS reason,
        {{ trim_make_empty_string_null('approval_status') }} AS approval_status,
        {{ trim_make_empty_string_null('issuer') }} AS issuer,
        {{ trim_make_empty_string_null('issuer_comment') }} AS issuer_comment,
        {{ safe_cast('created_time', type_timestamp()) }} AS created_time,
        {{ safe_cast('approved_time', type_timestamp()) }} AS approved_time,
        {{ trim_make_empty_string_null('settlement_status') }} AS settlement_status,
        {{ safe_cast('settlement_status_time', 'DATE') }} AS settlement_status_time,
        {{ trim_make_empty_string_null('settlement_reason_code') }} AS settlement_reason_code,
        {{ trim_make_empty_string_null('settlement_response_text') }} AS settlement_response_text,
        _line_number,
        `instance`,
        extract_filename,
        ts,
    FROM source
)

SELECT * FROM stg_littlepay__refunds
