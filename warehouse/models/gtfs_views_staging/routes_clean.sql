{{ config(materialized='table') }}

WITH routes AS (
    SELECT *
    FROM {{ source('gtfs_type2', 'routes') }}
),

routes_clean AS (

    -- Trim all string fields
    -- Incoming schema explicitly defined in gtfs_schedule_history external table definition

    SELECT
        calitp_itp_id,
        calitp_url_number,
        TRIM(route_id) AS route_id,
        TRIM(route_type) AS route_type,
        TRIM(agency_id) AS agency_id,
        TRIM(route_short_name) AS route_short_name,
        TRIM(route_long_name) AS route_long_name,
        TRIM(route_desc) AS route_desc,
        TRIM(route_url) AS route_url,
        TRIM(route_color) AS route_color,
        TRIM(route_text_color) AS route_text_color,
        TRIM(route_sort_order) AS route_sort_order,
        TRIM(continuous_pickup) AS continuous_pickup,
        TRIM(continuous_drop_off) AS continuous_drop_off,
        calitp_extracted_at,
        calitp_hash,
        {{ farm_surrogate_key(['calitp_hash', 'calitp_extracted_at']) }}
        AS route_key,
        COALESCE(calitp_deleted_at, "2099-01-01") AS calitp_deleted_at
    FROM routes
)

SELECT * FROM routes_clean
