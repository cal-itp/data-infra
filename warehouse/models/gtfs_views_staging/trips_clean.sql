{{ config(materialized='table') }}

WITH trips AS (
    SELECT *
    FROM {{ source('gtfs_type2', 'trips') }}
),

trips_clean AS (

    -- Trim all string fields
    -- Incoming schema explicitly defined in gtfs_schedule_history external table definition
    -- select distinct because of multiple duplicates, including from ITP ID 300 URL 0 on 2022-04-6
    SELECT DISTINCT
        calitp_itp_id,
        calitp_url_number,
        TRIM(route_id) AS route_id,
        TRIM(service_id) AS service_id,
        TRIM(trip_id) AS trip_id,
        TRIM(shape_id) AS shape_id,
        TRIM(trip_headsign) AS trip_headsign,
        TRIM(trip_short_name) AS trip_short_name,
        TRIM(direction_id) AS direction_id,
        TRIM(block_id) AS block_id,
        TRIM(wheelchair_accessible) AS wheelchair_accessible,
        TRIM(bikes_allowed) AS bikes_allowed,
        calitp_extracted_at,
        calitp_hash,
        {{ farm_surrogate_key(['calitp_hash', 'calitp_extracted_at']) }} AS trip_key,
        COALESCE(calitp_deleted_at, "2099-01-01") AS calitp_deleted_at
    FROM trips
)

SELECT * FROM trips_clean
