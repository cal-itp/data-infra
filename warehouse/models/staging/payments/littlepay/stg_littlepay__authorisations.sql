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
        -- we have two files with invalid names that cause attributes derived from filename to be missing
        CASE
            WHEN extract_filename = "24jan_datafeed.psv" THEN TIMESTAMP(DATE '2023-01-24')
            WHEN extract_filename = "25jan_datafeed.psv" THEN TIMESTAMP(DATE '2023-01-25')
            ELSE {{ extract_littlepay_filename_ts() }}
        END AS littlepay_export_ts,

        CASE
            WHEN extract_filename = "24jan_datafeed.psv" THEN DATE '2023-01-24'
            WHEN extract_filename = "25jan_datafeed.psv" THEN DATE '2023-01-25'
            ELSE {{ extract_littlepay_filename_date() }}
        END AS littlepay_export_date,
        ts,
    FROM source
    -- remove duplicate instances of the same file (file defined as date-level update from LP)
    QUALIFY DENSE_RANK()
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

        CASE
            WHEN extract_filename = "24jan_datafeed.psv" THEN DATE '2023-01-24'
            WHEN extract_filename = "25jan_datafeed.psv" THEN DATE '2023-01-25'
            ELSE littlepay_export_date
        END AS littlepay_export_date,
        ts,
        {{ dbt_utils.generate_surrogate_key(['littlepay_export_date', '_line_number', 'instance']) }} AS _key,
        {{ dbt_utils.generate_surrogate_key(['aggregation_id', 'retrieval_reference_number', 'authorisation_date_time_utc']) }} AS _payments_key,
    FROM clean_columns_and_dedupe_files
)

SELECT * FROM stg_littlepay__authorisations
