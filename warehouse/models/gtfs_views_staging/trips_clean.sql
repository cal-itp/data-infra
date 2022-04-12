{{ config(materialized='table') }}

WITH trips as (
    select *
    from {{ source('gtfs_type2', 'trips') }}
)

, trips_clean as (

    -- Trim all string fields
    -- Incoming schema explicitly defined in gtfs_schedule_history external table definition
    -- select distinct because of multiple duplicates, including from ITP ID 300 URL 0 on 2022-04-6
    SELECT DISTINCT
        calitp_itp_id
        , calitp_url_number
        , TRIM(route_id) as route_id
        , TRIM(service_id) as service_id
        , TRIM(trip_id) as trip_id
        , TRIM(shape_id) as shape_id
        , TRIM(trip_headsign) as trip_headsign
        , TRIM(trip_short_name) as trip_short_name
        , TRIM(direction_id) as direction_id
        , TRIM(block_id) as block_id
        , TRIM(wheelchair_accessible) as wheelchair_accessible
        , TRIM(bikes_allowed) as bikes_allowed
        , calitp_extracted_at
        , calitp_hash
        , FARM_FINGERPRINT(CONCAT(CAST(calitp_hash AS STRING), "___", CAST(calitp_extracted_at AS STRING))) AS trip_key
        , COALESCE(calitp_deleted_at, "2099-01-01") AS calitp_deleted_at
    FROM trips
)

SELECT * FROM trips_clean
