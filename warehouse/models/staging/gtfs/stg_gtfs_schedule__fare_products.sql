WITH external_fare_products AS (
    SELECT *
    FROM {{ source('external_gtfs_schedule', 'fare_products') }}
),

stg_gtfs_schedule__fare_products AS (

    -- Trim all string fields
    -- Incoming schema explicitly defined in gtfs_schedule_history external table definition

    SELECT
        base64_url,
        ts,
        dt AS _dt,
        _line_number,
        {{ trim_make_empty_string_null('fare_product_id') }} AS fare_product_id,
        {{ trim_make_empty_string_null('fare_product_name') }} AS fare_product_name,
        {{ trim_make_empty_string_null('fare_media_id') }} AS fare_media_id,
        SAFE_CAST({{ trim_make_empty_string_null('amount') }} AS NUMERIC) AS amount,
        {{ trim_make_empty_string_null('currency') }} AS currency
    FROM external_fare_products
)

SELECT * FROM stg_gtfs_schedule__fare_products
