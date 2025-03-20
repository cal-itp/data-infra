WITH source AS (
    SELECT * FROM {{ source('external_littlepay_v3', 'settlements') }}
),

clean_columns AS (
    SELECT
        {{ trim_make_empty_string_null('settlement_id') }} AS settlement_id,
        {{ trim_make_empty_string_null('participant_id') }} AS participant_id,
        {{ trim_make_empty_string_null('aggregation_id') }} AS aggregation_id,
        {{ trim_make_empty_string_null('customer_id') }} AS customer_id,
        {{ trim_make_empty_string_null('funding_source_id') }} AS funding_source_id,

        -- renamed amount in v3, this was transaction_amount in v1
        {{ safe_cast('amount', type_numeric()) }} AS transaction_amount,
        {{ trim_make_empty_string_null('retrieval_reference_number') }} AS retrieval_reference_number,
        {{ trim_make_empty_string_null('littlepay_reference_number') }} AS littlepay_reference_number,
        {{ trim_make_empty_string_null('external_reference_number') }} AS external_reference_number,
        {{ trim_make_empty_string_null('settlement_type') }} AS settlement_type,

        -- renamed record_updated_timestamp_utc in v3, this was settlement_requested_date_time_utc in v1
        -- prior to 11/28/23, only ATN had record_updated_timestamp_utc
        -- per communication from LP, that column is the new name of settlement_requested_date_time_utc
        {{ safe_cast('record_updated_timestamp_utc', type_timestamp()) }} AS record_updated_timestamp_utc,

        -- renamed acquirer_code in v3, this was acquirer in v1
        {{ trim_make_empty_string_null('acquirer_code') }} AS acquirer,
        {{ trim_make_empty_string_null('refund_id') }} AS refund_id,
        {{ safe_cast('request_created_timestamp_utc', type_timestamp()) }} AS request_created_timestamp_utc,
        {{ safe_cast('response_created_timestamp_utc', type_timestamp()) }} AS response_created_timestamp_utc,
        {{ trim_make_empty_string_null('acquirer_response_rrn') }} AS acquirer_response_rrn,
        {{ trim_make_empty_string_null('settlement_status') }} AS settlement_status,

        -- these are new fields in v3, excluding for now to faciliate union with feed v1
        -- transaction_timestamp_utc,
        -- currency_code,
        -- channel,

        CAST(_line_number AS INTEGER) AS _line_number,
        `instance`,
        extract_filename,
        ts,
        {{ extract_littlepay_filename_ts() }} AS littlepay_export_ts,
        {{ extract_littlepay_filename_date() }} AS littlepay_export_date,
        {{ dbt_utils.generate_surrogate_key(['participant_id',
        'settlement_id', 'aggregation_id', 'customer_id', 'funding_source_id', 'amount',
        'retrieval_reference_number', 'littlepay_reference_number', 'external_reference_number',
        'settlement_type', 'record_updated_timestamp_utc', 'acquirer_code']) }} AS _content_hash,
    FROM source
),

dedupe_and_keys AS (
    SELECT
        *,
        -- generate keys now that input columns have been trimmed & cast
        {{ dbt_utils.generate_surrogate_key(['littlepay_export_ts', '_line_number', 'instance']) }} AS _key,
        {{ dbt_utils.generate_surrogate_key(['settlement_id']) }} AS _payments_key
    FROM clean_columns
    {{ qualify_dedupe_full_duplicate_lp_rows() }}
),

stg_littlepay__settlements_v3 AS (
        SELECT
        settlement_id,
        participant_id,
        aggregation_id,
        customer_id,
        funding_source_id,
        transaction_amount,
        retrieval_reference_number,
        littlepay_reference_number,
        external_reference_number,
        settlement_type,
        record_updated_timestamp_utc,
        acquirer,
        refund_id,
        acquirer_response_rrn,
        settlement_status,
        request_created_timestamp_utc,
        response_created_timestamp_utc,

        -- these are new fields in v3, excluding for now to faciliate union with feed v1
        -- transaction_timestamp_utc,
        -- currency_code,
        -- channel,

        _line_number,
        `instance`,
        extract_filename,
        ts,
        _content_hash,
        littlepay_export_ts,
        littlepay_export_date,
        _key,
        _payments_key
    FROM dedupe_and_keys
)

SELECT * FROM stg_littlepay__settlements_v3
