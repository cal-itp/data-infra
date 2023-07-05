{{
    config(
        materialized='incremental',
        unique_key = 'key',
        cluster_by = ['service_date', 'base64_url'],
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
        service_date,
        base64_url,
        trip_id,
        trip_start_time,
        trip_instance_key
    FROM {{ ref('fct_vehicle_positions_trip_summaries') }}
),

first_keying_and_filtering AS (
    SELECT * EXCEPT (key),
        {{ dbt_utils.generate_surrogate_key(['service_date', 'base64_url', 'location_timestamp', 'vehicle_id', 'vehicle_label', 'trip_id', 'trip_start_time']) }} AS key,
        {{ dbt_utils.generate_surrogate_key(['service_date', 'base64_url', 'vehicle_id', 'vehicle_label', 'trip_id', 'trip_start_time']) }} AS vehicle_trip_key
    FROM fct_vehicle_positions_messages
    -- drop cases where trip id is null since these cannot be joined to schedule
    -- this is something we may want to reconsider
    -- TODO: theoretically we need to eventually support route / direction / start date / start time as an alternate trip identifier
    WHERE trip_id IS NOT NULL
    -- we originally dropped the Bay Area regional feed because they don't make their vehicle identifiers unique by agency
    -- so you can end up intermingling multiple vehicles
    -- however, not clear this issue remains if we are also dropping rows with no trip
    -- since regional feed does have unique trip IDs per agency
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
        ON deduped.service_date = vp_trips.service_date
        AND deduped.trip_id = vp_trips.trip_id
        AND deduped.base64_url = vp_trips.base64_url
        -- this is often null but we need to include it for frequency based trips
        AND COALESCE(deduped.trip_start_time, "") = COALESCE(vp_trips.trip_start_time, "")
)

SELECT * FROM fct_vehicle_locations
