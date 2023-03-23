WITH source AS (
    SELECT * FROM {{ source('external_littlepay', 'refunds') }}
),

stg_littlepay__refunds AS (
    SELECT
        refund_id,
        participant_id,
        customer_id,
        micropayment_id,
        aggregation_id,
        settlement_id,
        retrieval_reference_number,
        {{ safe_cast('transaction_date', 'DATE') }} AS transaction_date,
        {{ safe_cast('transaction_amount', type_numeric()) }} AS transaction_amount,
        {{ safe_cast('proposed_amount', type_numeric()) }} AS proposed_amount,
        {{ safe_cast('refund_amount', type_numeric()) }} AS refund_amount,
        {{ safe_cast('currency_code', type_int()) }} AS currency_code,
        status,
        initiator,
        reason,
        approval_status,
        issuer,
        issuer_comment,
        {{ safe_cast('created_time', type_timestamp()) }} AS created_time,
        {{ safe_cast('approved_time', type_timestamp()) }} AS approved_time,
        settlement_status,
        {{ safe_cast('settlement_status_time', 'DATE') }} AS settlement_status_time,
        settlement_reason_code,
        settlement_response_text,
        _line_number,
        `instance`,
        extract_filename,
        ts,
    FROM source
)

SELECT * FROM stg_littlepay__refunds
