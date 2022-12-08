WITH external_routes AS (
    SELECT *
    FROM {{ source('external_gtfs_schedule', 'routes') }}
),

stg_gtfs_schedule__routes AS (

    -- Trim all string fields
    -- Incoming schema explicitly defined in external table definition

    SELECT
        base64_url,
        ts,
        {{ trim_make_empty_string_null('route_id') }} AS route_id,
        {{ trim_make_empty_string_null('route_type') }} AS route_type,
        {{ trim_make_empty_string_null('agency_id') }} AS agency_id,
        {{ trim_make_empty_string_null('route_short_name') }} AS route_short_name,
        {{ trim_make_empty_string_null('route_long_name') }} AS route_long_name,
        {{ trim_make_empty_string_null('route_desc') }} AS route_desc,
        {{ trim_make_empty_string_null('route_url') }} AS route_url,
        {{ trim_make_empty_string_null('route_color') }} AS route_color,
        {{ trim_make_empty_string_null('route_text_color') }} AS route_text_color,
        SAFE_CAST({{ trim_make_empty_string_null('route_sort_order') }} AS INTEGER) AS route_sort_order,
        SAFE_CAST({{ trim_make_empty_string_null('continuous_pickup') }} AS INTEGER) AS continuous_pickup,
        SAFE_CAST({{ trim_make_empty_string_null('continuous_drop_off') }} AS INTEGER) AS continuous_drop_off,
        {{ trim_make_empty_string_null('network_id') }} AS network_id,
    FROM external_routes
)

SELECT * FROM stg_gtfs_schedule__routes
