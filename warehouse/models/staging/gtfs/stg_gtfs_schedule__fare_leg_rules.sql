WITH external_fare_leg_rules AS (
    SELECT *
    FROM {{ source('external_gtfs_schedule', 'fare_leg_rules') }}
),

stg_gtfs_schedule__fare_leg_rules AS (

    -- Trim all string fields
    -- Incoming schema explicitly defined in gtfs_schedule_history external table definition

    SELECT
        base64_url,
        ts,
        dt AS _dt,
        {{ trim_make_empty_string_null('leg_group_id') }} AS leg_group_id,
        {{ trim_make_empty_string_null('networK_id') }} AS network_id,
        {{ trim_make_empty_string_null('from_area_id') }} AS from_area_id,
        {{ trim_make_empty_string_null('to_area_id') }} AS to_area_id,
        {{ trim_make_empty_string_null('fare_product_id') }} AS fare_product_id
    FROM external_fare_leg_rules
)

SELECT * FROM stg_gtfs_schedule__fare_leg_rules
