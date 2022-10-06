WITH external_routes AS (
    SELECT *
    FROM {{ source('external_gtfs_history', 'routes') }}
),

stg_gtfs_schedule__routes AS (

    -- Trim all string fields
    -- Incoming schema explicitly defined in external table definition

    SELECT
        base64_url,
        ts,
        TRIM(route_id) AS route_id,
        TRIM(route_type) AS route_type,
        TRIM(agency_id) AS agency_id,
        TRIM(route_short_name) AS route_short_name,
        TRIM(route_long_name) AS route_long_name,
        TRIM(route_desc) AS route_desc,
        TRIM(route_url) AS route_url,
        TRIM(route_color) AS route_color,
        TRIM(route_text_color) AS route_text_color,
        CAST(TRIM(route_sort_order) AS INTEGER) AS route_sort_order,
        CAST(TRIM(continuous_pickup) AS INTEGER) AS continuous_pickup,
        CAST(TRIM(continuous_drop_off) AS INTEGER) AS continuous_drop_off
    FROM external_routes
)

SELECT * FROM stg_gtfs_schedule__routes
