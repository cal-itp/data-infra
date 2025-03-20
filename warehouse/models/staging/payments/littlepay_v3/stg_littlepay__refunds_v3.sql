WITH source AS (
    SELECT * FROM {{ source('external_littlepay_v3', 'refunds') }}
),

clean_columns AS (
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
        {{ trim_make_empty_string_null('initiator') }} AS initiator,
        {{ trim_make_empty_string_null('reason') }} AS reason,
        {{ trim_make_empty_string_null('approval_status') }} AS approval_status,
        {{ trim_make_empty_string_null('issuer') }} AS issuer,
        {{ trim_make_empty_string_null('issuer_comment') }} AS issuer_comment,
        {{ safe_cast('refund_created_timestamp_utc', type_timestamp()) }} AS created_time,
        {{ safe_cast('refund_approved_timestamp_utc', type_timestamp()) }} AS approved_time,

        -- these fields are deprecated in v3, reasoning in comments below
        -- but adding them here as null strings for the union with v1, so as to not risk breaking dashboards
        {{ trim_make_empty_string_null("''") }} AS settlement_reason_code, -- removed (not in use)
        {{ trim_make_empty_string_null("''") }} AS settlement_response_text, -- removed (not in use)
        {{ trim_make_empty_string_null("''") }} AS status, -- removed, use refund_id to link to the credit settlement to get the latest status
        {{ trim_make_empty_string_null("''") }} AS settlement_status, -- removed, use refund_id to link to the credit settlement to get the latest status
        {{ safe_cast("''", 'DATE') }} AS settlement_status_time, -- removed, use refund_id to link to the credit settlement to get the latest status

        CAST(_line_number AS INTEGER) AS _line_number,
        `instance`,
        extract_filename,
        ts,
        {{ extract_littlepay_filename_ts() }} AS littlepay_export_ts,
        {{ extract_littlepay_filename_date() }} AS littlepay_export_date,

        -- removed the following fields from hash used in v1 because they are removed in v3:
        -- settlement_reason_code, settlement_response_text, status, settlement_status, settlement_status_time
        {{ dbt_utils.generate_surrogate_key(['participant_id',
        'refund_id', 'aggregation_id', 'customer_id', 'micropayment_id', 'settlement_id',
        'retrieval_reference_number', 'transaction_date', 'transaction_amount',
        'proposed_amount', 'refund_amount', 'currency_code', 'initiator', 'reason', 'approval_status', 'issuer',
        'issuer_comment', 'refund_created_timestamp_utc', 'refund_approved_timestamp_utc',
        ]) }} AS _content_hash,
    FROM source
),

stg_littlepay__refunds_v3 AS (
    SELECT
        refund_id,
        participant_id,
        customer_id,
        micropayment_id,
        aggregation_id,
        settlement_id,
        retrieval_reference_number,
        transaction_date,
        transaction_amount,
        proposed_amount,
        refund_amount,
        currency_code,
        status,
        initiator,
        reason,
        approval_status,
        issuer,
        issuer_comment,
        created_time,
        approved_time,
        settlement_status,
        settlement_status_time,
        settlement_reason_code,
        settlement_response_text,
        CAST(_line_number AS INTEGER) AS _line_number,
        `instance`,
        extract_filename,
        ts,
        littlepay_export_ts,
        littlepay_export_date,
        _content_hash,
        -- generate keys now that input columns have been trimmed & cast
        {{ dbt_utils.generate_surrogate_key(['littlepay_export_ts', '_line_number', 'instance']) }} AS _key,
        -- we have multiple rows for some refunds as the refund moves through different statuses; we should handle this later
        {{ dbt_utils.generate_surrogate_key(['refund_id', 'approval_status']) }} AS _payments_key
    FROM clean_columns
)

SELECT * FROM stg_littlepay__refunds_v3
