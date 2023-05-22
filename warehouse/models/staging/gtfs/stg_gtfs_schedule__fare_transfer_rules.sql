WITH external_fare_transfer_rules AS (
    SELECT *
    FROM {{ source('external_gtfs_schedule', 'fare_transfer_rules') }}
),

stg_gtfs_schedule__fare_transfer_rules AS (

    -- Trim all string fields
    -- Incoming schema explicitly defined in gtfs_schedule_history external table definition

    SELECT
        base64_url,
        ts,
        dt AS _dt,
        _line_number,
        {{ trim_make_empty_string_null('from_leg_group_id') }} AS from_leg_group_id,
        {{ trim_make_empty_string_null('to_leg_group_id') }} AS to_leg_group_id,
        SAFE_CAST({{ trim_make_empty_string_null('transfer_count') }} AS INTEGER) AS transfer_count,
        SAFE_CAST({{ trim_make_empty_string_null('duration_limit') }} AS INTEGER) AS duration_limit,
        SAFE_CAST({{ trim_make_empty_string_null('duration_limit_type') }} AS INTEGER) AS duration_limit_type,
        SAFE_CAST({{ trim_make_empty_string_null('fare_transfer_type') }} AS INTEGER) AS fare_transfer_type,
        {{ trim_make_empty_string_null('fare_product_id') }} AS fare_product_id
    FROM external_fare_transfer_rules
)

SELECT * FROM stg_gtfs_schedule__fare_transfer_rules
