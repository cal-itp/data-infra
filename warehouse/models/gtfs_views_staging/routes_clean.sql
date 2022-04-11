{{ config(materialized='table') }}

WITH type2 as (
    select *
    from {{ source('gtfs_type2', 'routes') }}
)

, routes_clean as (

    -- Trim all string fields
    -- Incoming schema explicitly defined in gtfs_schedule_history external table definition

    SELECT
        calitp_itp_id
        , calitp_url_number
        , TRIM(route_id) as route_id
        , TRIM(route_type) as route_type
        , TRIM(agency_id) as agency_id
        , TRIM(route_short_name) as route_short_name
        , TRIM(route_long_name) as route_long_name
        , TRIM(route_desc) as route_desc
        , TRIM(route_url) as route_url
        , TRIM(route_color) as route_color
        , TRIM(route_text_color) as route_text_color
        , TRIM(route_sort_order) as route_sort_order
        , TRIM(continuous_pickup) as continuous_pickup
        , TRIM(continuous_drop_off) as continuous_drop_off
        , calitp_extracted_at
        , calitp_hash
        , FARM_FINGERPRINT(CONCAT(CAST(calitp_hash AS STRING), "___", CAST(calitp_extracted_at AS STRING)))
            AS route_key
        , COALESCE(calitp_deleted_at, "2099-01-01") AS calitp_deleted_at
    FROM type2
)

SELECT * FROM routes_clean
