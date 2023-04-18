WITH source AS (
    SELECT * FROM {{ source('external_littlepay', 'authorisations') }}
),

stg_littlepay__authorisations AS (
    SELECT
        participant_id,
        aggregation_id,
        acquirer_id,
        request_type,
        {{ safe_cast('transaction_amount', type_numeric()) }} AS transaction_amount,
        {{ safe_cast('currency_code', type_int()) }} AS currency_code,
        retrieval_reference_number,
        littlepay_reference_number,
        external_reference_number,
        response_code,
        status,
        {{ safe_cast('authorisation_date_time_utc', type_timestamp()) }} AS authorisation_date_time_utc,
        _line_number,
        `instance`,
        extract_filename,
        ts,
    FROM source
)

SELECT * FROM stg_littlepay__authorisations
