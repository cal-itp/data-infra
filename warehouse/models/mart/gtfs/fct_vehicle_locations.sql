
WITH

fct_vehicle_positions_messages AS (
    SELECT * FROM {{ ref('fct_vehicle_positions_messages') }}
)

, coalesced_and_filtered AS (
    SELECT *
        , COALESCE(vehicle_timestamp, header_timestamp) AS vehicle_timestamp
    FROM fct_vehicle_positions_messages
    WHERE trip_id IS NOT NULL
)

, deduped AS (
    SELECT * FROM fct_vehicle_positions_messages
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY namel, ts ORDER BY null
    ) = 1
)

, fct_vehicle_locations AS (

)

SELECT * FROM fct_vehicle_locations
