WITH source AS (
    SELECT * FROM {{ source('external_littlepay', 'authorisations') }}
),

clean_columns_and_dedupe_files AS (
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
        CAST(_line_number AS INTEGER) AS _line_number,
        `instance`,
        extract_filename,
        {{ extract_littlepay_filename_ts() }} AS littlepay_export_ts,
        {{ extract_littlepay_filename_date() }} AS littlepay_export_date,
        ts,
    FROM source
    -- remove duplicate instances of the same file (file defined as date-level update from LP)
    QUALIFY ROW_NUMBER()
        OVER (PARTITION BY littlepay_export_date ORDER BY littlepay_export_ts DESC, ts DESC) = 1
),

stg_littlepay__authorisations AS (
    SELECT
        participant_id,
        aggregation_id,
        acquirer_id,
        request_type,
        transaction_amount,
        currency_code,
        retrieval_reference_number,
        littlepay_reference_number,
        external_reference_number,
        response_code,
        status,
        authorisation_date_time_utc,
         _line_number,
        `instance`,
        extract_filename,
        littlepay_export_ts,
        littlepay_export_date,
        ts,
        {{ dbt_utils.generate_surrogate_key(['littlepay_export_date', '_line_number']) }} AS _key,
    FROM clean_columns_and_dedupe_files
)

SELECT * FROM stg_littlepay__authorisations
