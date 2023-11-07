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
        -- as of 10/6/23, only ATN has record_updated_timestamp_utc
        -- per communication from LP, that column is the new name of settlement_requested_date_time_utc
        COALESCE(
            {{ safe_cast('settlement_requested_date_time_utc', type_timestamp()) }},
            {{ safe_cast('record_updated_timestamp_utc', type_timestamp()) }}
            ) AS settlement_requested_date_time_utc,
        {{ trim_make_empty_string_null('acquirer') }} AS acquirer,
        CAST(_line_number AS INTEGER) AS _line_number,
        -- TODO: add "new schema" columns that are present only for ATN as of 10/6/23
        `instance`,
        extract_filename,
        ts,
        {{ extract_littlepay_filename_ts() }} AS littlepay_export_ts,
        {{ extract_littlepay_filename_date() }} AS littlepay_export_date,
        {{ dbt_utils.generate_surrogate_key(['participant_id',
        'settlement_id', 'aggregation_id', 'customer_id', 'funding_source_id', 'transaction_amount',
        'retrieval_reference_number', 'littlepay_reference_number', 'external_reference_number',
        'settlement_type', 'settlement_requested_date_time_utc', 'acquirer']) }} AS _content_hash,
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
        settlement_requested_date_time_utc,
        acquirer,
        _line_number,
        -- TODO: add "new schema" columns that are present only for ATN as of 10/6/23
        `instance`,
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
