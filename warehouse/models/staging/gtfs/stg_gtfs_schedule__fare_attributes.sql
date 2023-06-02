WITH external_fare_attributes AS (
    SELECT *
    FROM {{ source('external_gtfs_schedule', 'fare_attributes') }}
),

stg_gtfs_schedule__fare_attributes AS (

    -- Trim all string fields
    -- Incoming schema explicitly defined in gtfs_schedule_history external table definition

    SELECT
        base64_url,
        ts,
        dt AS _dt,
        _line_number,
        {{ trim_make_empty_string_null('fare_id') }} AS fare_id,
        {{ trim_make_empty_string_null('price') }} AS price,
        {{ trim_make_empty_string_null('currency_type') }} AS currency_type,
        SAFE_CAST({{ trim_make_empty_string_null('payment_method') }} AS INTEGER) AS payment_method,
        SAFE_CAST({{ trim_make_empty_string_null('transfers') }} AS INTEGER) AS transfers,
        {{ trim_make_empty_string_null('agency_id') }} AS agency_id,
        SAFE_CAST({{ trim_make_empty_string_null('transfer_duration') }} AS INTEGER) AS transfer_duration

    FROM external_fare_attributes
)

SELECT * FROM stg_gtfs_schedule__fare_attributes
