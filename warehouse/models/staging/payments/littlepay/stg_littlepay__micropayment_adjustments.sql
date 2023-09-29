WITH source AS (
    SELECT * FROM {{ littlepay_source('external_littlepay', 'micropayment_adjustments') }}
),

stg_littlepay__micropayment_adjustments AS (
    SELECT
        {{ trim_make_empty_string_null('micropayment_id') }} AS micropayment_id,
        {{ trim_make_empty_string_null('adjustment_id') }} AS adjustment_id,
        {{ trim_make_empty_string_null('participant_id') }} AS participant_id,
        {{ trim_make_empty_string_null('customer_id') }} AS customer_id,
        {{ trim_make_empty_string_null('product_id') }} AS product_id,
        {{ trim_make_empty_string_null('type') }} AS type,
        {{ trim_make_empty_string_null('description') }} AS description,
        {{ trim_make_empty_string_null('amount') }} AS amount,
        {{ trim_make_empty_string_null('time_period_type') }} AS time_period_type,
        {{ safe_cast('applied', type_boolean()) }} AS applied,
        {{ trim_make_empty_string_null('zone_ids_us') }} AS zone_ids_us,
        _line_number,
        `instance`,
        extract_filename,
        ts,
    FROM source
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY
            micropayment_id,
            adjustment_id,
            participant_id,
            customer_id,
            product_id,
            type,
            description,
            amount,
            time_period_type,
            applied,
            zone_ids_us
        ORDER BY littlepay_export_ts DESC
    ) = 1
)

SELECT * FROM stg_littlepay__micropayment_adjustments
