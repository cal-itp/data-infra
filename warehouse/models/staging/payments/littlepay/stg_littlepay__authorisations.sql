WITH source AS (
    SELECT * FROM {{ source('external_littlepay', 'authorisations') }}
),

stg_littlepay__authorisations AS (
    SELECT
        {{ trim_make_empty_string_null('participant_id') }} AS participant_id,
        {{ trim_make_empty_string_null('aggregation_id') }} AS aggregation_id,
        {{ trim_make_empty_string_null('acquirer_id') }} AS acquirer_id,
        {{ trim_make_empty_string_null('request_type') }} AS request_type,
        {{ safe_cast('transaction_amount', type_numeric()) }} AS transaction_amount,
        {{ safe_cast('currency_code', type_int()) }} AS currency_code,
        {{ trim_make_empty_string_null('retrieval_reference_number') }} AS retrieval_reference_number,
        {{ trim_make_empty_string_null('littlepay_reference_number') }} AS littlepay_reference_number,
        {{ trim_make_empty_string_null('external_reference_number') }} AS external_reference_number,
        {{ trim_make_empty_string_null('response_code') }} AS response_code,
        {{ trim_make_empty_string_null('status') }} AS status,
        {{ safe_cast('authorisation_date_time_utc', type_timestamp()) }} AS authorisation_date_time_utc,
        _line_number,
        `instance`,
        extract_filename,
        ts,
    FROM source
)

SELECT * FROM stg_littlepay__authorisations
