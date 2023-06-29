{{
    config(
        materialized='incremental',
        unique_key = 'key',
        cluster_by = ['calculated_service_date', 'base64_url'],
    )
}}

WITH fct_vehicle_positions_messages AS (
    SELECT *,
        COALESCE(vehicle_timestamp, header_timestamp) AS location_timestamp
    FROM {{ ref('fct_vehicle_positions_messages') }}
    WHERE {{ incremental_where(default_start_var='PROD_GTFS_RT_START') }}
),

vp_trips AS (
    SELECT
        calculated_service_date,
        base64_url,
        trip_id,
        trip_start_time,
        trip_instance_key
    FROM {{ ref('fct_vehicle_positions_trip_summaries') }}
),

first_keying_and_filtering AS (
    SELECT * EXCEPT (key),
        {{ dbt_utils.generate_surrogate_key(['calculated_service_date', 'base64_url', 'location_timestamp', 'vehicle_id', 'vehicle_label', 'trip_id', 'trip_start_time']) }} AS key,
        {{ dbt_utils.generate_surrogate_key(['calculated_service_date', 'base64_url', 'vehicle_id', 'vehicle_label', 'trip_id', 'trip_start_time']) }} AS vehicle_trip_key
    FROM fct_vehicle_positions_messages
    WHERE trip_id IS NOT NULL
        AND name != 'Bay Area 511 Regional VehiclePositions'
),

deduped AS (
    SELECT *
    FROM first_keying_and_filtering
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY key
        ORDER BY position_latitude, position_longitude
    ) = 1
),

fct_vehicle_locations AS (
    SELECT deduped.*,
        LEAD(key) OVER (PARTITION BY vehicle_trip_key ORDER BY location_timestamp) AS next_location_key,
        ST_GEOGPOINT(position_longitude, position_latitude) AS location,
        trip_instance_key
    FROM deduped
    LEFT JOIN vp_trips
        ON deduped.calculated_service_date = vp_trips.calculated_service_date
        AND deduped.trip_id = vp_trips.trip_id
        AND deduped.base64_url = vp_trips.base64_url
        -- this is often null but we need to include it for frequency based trips
        AND COALESCE(deduped.trip_start_time, "") = COALESCE(vp_trips.trip_start_time, "")
)

SELECT * FROM fct_vehicle_locations
