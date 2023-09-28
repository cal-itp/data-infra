WITH source AS (
    SELECT * FROM {{ littlepay_source('external_littlepay', 'product_data') }}
),

stg_littlepay__product_data AS (
    SELECT
        {{ trim_make_empty_string_null('participant_id') }} AS participant_id,
        {{ trim_make_empty_string_null('product_id') }} AS product_id,
        {{ trim_make_empty_string_null('product_code') }} AS product_code,
        {{ trim_make_empty_string_null('product_description') }} AS product_description,
        {{ trim_make_empty_string_null('product_type') }} AS product_type,
        {{ trim_make_empty_string_null('activation_type') }} AS activation_type,
        {{ trim_make_empty_string_null('product_status') }} AS product_status,
        {{ trim_make_empty_string_null('created_date') }} AS created_date,
        {{ trim_make_empty_string_null('capping_type') }} AS capping_type,
        {{ safe_cast('multi_operator', type_boolean()) }} AS multi_operator,
        {{ safe_cast('capping_start_time', 'TIME') }} AS capping_start_time,
        {{ safe_cast('capping_end_time', 'TIME') }} AS capping_end_time,
        {{ trim_make_empty_string_null('rules_transaction_types') }} AS rules_transaction_types,
        {{ trim_make_empty_string_null('rules_default_limit') }} AS rules_default_limit,
        {{ trim_make_empty_string_null('rules_max_fare_value') }} AS rules_max_fare_value,
        {{ safe_cast('scheduled_start_date_time', 'DATE') }} AS scheduled_start_date_time,
        {{ safe_cast('scheduled_end_date_time', 'DATE') }} AS scheduled_end_date_time,
        {{ safe_cast('all_day', type_boolean()) }} AS all_day,
        {{ trim_make_empty_string_null('weekly_cap_start_day') }} AS weekly_cap_start_day,
        {{ safe_cast('number_of_days_in_cap_window', type_float()) }} AS number_of_days_in_cap_window,
        {{ safe_cast('capping_duration', type_float()) }} AS capping_duration,
        {{ safe_cast('number_of_transfer', type_float()) }} AS number_of_transfer,
        {{ trim_make_empty_string_null('capping_time_zone') }} AS capping_time_zone,
        {{ safe_cast('capping_overlap', 'TIME') }} AS capping_overlap,
        {{ trim_make_empty_string_null('capping_application_level') }} AS capping_application_level,
        _line_number,
        `instance`,
        extract_filename,
        ts,
    FROM source
    QUALIFY ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY littlepay_export_ts DESC) = 1
)

SELECT * FROM stg_littlepay__product_data
