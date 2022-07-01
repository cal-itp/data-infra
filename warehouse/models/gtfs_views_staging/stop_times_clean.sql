{{ config(materialized='table') }}

WITH stop_times AS (
    SELECT *
    FROM {{ source('gtfs_type2', 'stop_times') }}
),

stop_times_clean AS (

    -- Trim all string fields
    -- Incoming schema explicitly defined in gtfs_schedule_history external table definition

    SELECT
        calitp_itp_id,
        calitp_url_number,
        TRIM(trip_id) AS trip_id,
        TRIM(stop_id) AS stop_id,
        TRIM(stop_sequence) AS stop_sequence,
        TRIM(arrival_time) AS arrival_time,
        TRIM(departure_time) AS departure_time,
        TRIM(stop_headsign) AS stop_headsign,
        TRIM(pickup_type) AS pickup_type,
        TRIM(drop_off_type) AS drop_off_type,
        TRIM(continuous_pickup) AS continuous_pickup,
        TRIM(continuous_drop_off) AS continuous_drop_off,
        TRIM(shape_dist_traveled) AS shape_dist_traveled,
        TRIM(timepoint) AS timepoint,
        calitp_extracted_at,
        calitp_hash,
        {{ farm_surrogate_key(['calitp_hash', 'calitp_extracted_at']) }}
        AS stop_time_key,
        COALESCE(calitp_deleted_at, "2099-01-01") AS calitp_deleted_at
    FROM stop_times
)

SELECT * FROM stop_times_clean
