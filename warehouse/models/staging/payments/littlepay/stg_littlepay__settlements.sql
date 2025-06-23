WITH source AS (
    SELECT * FROM {{ source('external_littlepay', 'settlements') }}
),

clean_columns AS (
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
        {{ trim_make_empty_string_null('settlement_type') }} AS settlement_type,
        -- prior to 11/28/23, only ATN had record_updated_timestamp_utc
        -- per communication from LP, that column is the new name of settlement_requested_date_time_utc
        COALESCE(
            {{ safe_cast('record_updated_timestamp_utc', type_timestamp()) }},
            {{ safe_cast('settlement_requested_date_time_utc', type_timestamp()) }}
            ) AS record_updated_timestamp_utc,
        {{ trim_make_empty_string_null('acquirer') }} AS acquirer,
        {{ trim_make_empty_string_null('refund_id') }} AS refund_id,
        {{ safe_cast('request_created_timestamp_utc', type_timestamp()) }} AS request_created_timestamp_utc,
        {{ safe_cast('response_created_timestamp_utc', type_timestamp()) }} AS response_created_timestamp_utc,
        {{ trim_make_empty_string_null('acquirer_response_rrn') }} AS acquirer_response_rrn,
        {{ trim_make_empty_string_null('settlement_status') }} AS settlement_status,
        CAST(_line_number AS INTEGER) AS _line_number,
        `instance`,
        extract_filename,
        ts,
        {{ extract_littlepay_filename_ts() }} AS littlepay_export_ts,
        {{ extract_littlepay_filename_date() }} AS littlepay_export_date,
        {{ dbt_utils.generate_surrogate_key(['participant_id',
        'settlement_id', 'aggregation_id', 'customer_id', 'funding_source_id', 'transaction_amount',
        'retrieval_reference_number', 'littlepay_reference_number', 'external_reference_number',
        'settlement_type', 'record_updated_timestamp_utc', 'acquirer']) }} AS _content_hash,
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

stg_littlepay__settlements AS (
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
        -- manual backfill of ccjpa data for specific reporting needs
        -- information on how to backfill comes from manual LP extracts provided by Rebel
        CASE
            WHEN _key IN ("4e0bf943884f81fd6e524f4e175139c0", "910e0fe9c6f78de301b69f35798ec613", "8df624e5048128983c9693faaa32f27d", "67e002b1be3f07b2c06b4335364d7fde", "f658f3201463764ceea23816e9c27a54", "5878d1e840d94938d8fd2f1d33d44f1d", "df5c48e3d9d21f20be7da9d5973d1b8e", "58f6955a6b52f5b12d0999bcccb712fb", "6724c21016dc153517bc0b55fe4bc6b2")
                THEN "REJECTED"
            WHEN participant_id = "ccjpa"
                AND littlepay_export_date < "2023-11-28"
                THEN "SETTLED"
            ELSE settlement_status
        END AS settlement_status,
        request_created_timestamp_utc,
        response_created_timestamp_utc,
        _line_number,
        `instance`,
        'v1' AS feed_version,
        extract_filename,
        ts,
        _content_hash,
        littlepay_export_ts,
        littlepay_export_date,
        _key,
        _payments_key
    FROM dedupe_and_keys
    -- we have just two duplicates on settlement id; they are not associated with a refund
    -- drop these two cases so that we can continue testing for absolute uniqueness
    -- if we get more cases, we can add a qualify to get latest appearance only
    WHERE _key NOT IN ("bc6dd0f735a1087b13b424a3c790fc4d", "e8c09f593df1c61c9a890da0935d0863")
    -- this second drop is a separate issue: we have one single case of a duplicate aggregation_id with separate RRNs
    -- dropping the first of these two settlements based on cross-referencing with authorisations
        AND _key != "e8c25be12ecf1f0ec610771422c6efc8"
)

SELECT * FROM stg_littlepay__settlements
