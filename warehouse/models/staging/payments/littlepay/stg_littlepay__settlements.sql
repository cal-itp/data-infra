WITH source AS (
    SELECT * FROM {{ source('external_littlepay', 'settlements') }}
),

stg_littlepay__settlements AS (
    SELECT
        settlement_id,
        participant_id,
        aggregation_id,
        customer_id,
        funding_source_id,
        {{ safe_cast('transaction_amount', type_numeric()) }} AS transaction_amount,
        retrieval_reference_number,
        littlepay_reference_number,
        external_reference_number,
        {{ safe_cast('settlement_requested_date_time_utc', type_timestamp()) }} AS settlement_requested_date_time_utc,
        acquirer,
        _line_number,
        `instance`,
        extract_filename,
        ts
    FROM source
)

SELECT * FROM stg_littlepay__settlements
