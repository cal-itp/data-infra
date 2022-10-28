
WITH

-- base64_url
-- header_timestamp
-- vehicle_timestamp
-- vehicle_id
-- trip_id
-- is unique
fct_vehicle_positions_messages AS (
    SELECT * FROM {{ ref('fct_vehicle_positions_messages') }}
)

, coalesced_and_filtered AS (
    SELECT * EXCEPT (key)
        , COALESCE(vehicle_timestamp, header_timestamp) AS location_timestamp
    FROM fct_vehicle_positions_messages
    WHERE trip_id IS NOT NULL
        AND _gtfs_dataset_name != 'Bay Area 511 Regional VehiclePositions'
)

, deduped AS (
    SELECT *
    FROM coalesced_and_filtered
    QUALIFY ROW_NUMBER() OVER (
        -- the dt is necessary to preserve partition elimination in downstream queries
        PARTITION BY dt, base64_url, location_timestamp, vehicle_id, trip_id
        ORDER BY NULL
    ) = 1
)

, fct_vehicle_locations AS (
    SELECT *,
        {{ dbt_utils.surrogate_key(['base64_url', 'location_timestamp', 'vehicle_id', 'trip_id']) }} AS key
    FROM deduped
)

SELECT * FROM fct_vehicle_locations
