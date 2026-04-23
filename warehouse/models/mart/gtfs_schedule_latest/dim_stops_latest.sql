WITH
dim_stops_latest AS (
    {{ get_latest_schedule_data(
    table_name = ref('dim_stops'),
    clean_table_name = 'dim_stops'
    ) }}
),

stg_state_geoportal__state_highway_network_stops AS (
    SELECT *
    FROM {{ ref('stg_state_geoportal__state_highway_network_stops') }}
),


buffer_geometry_table AS (
    -- 30.48 = 100ft
    SELECT ST_BUFFER(wkt_coordinates, 30.48) AS buffer_geometry
    FROM stg_state_geoportal__state_highway_network_stops
),

current_stops AS (
    SELECT
        pt_geom,
        _gtfs_key
    FROM dim_stops_latest
),

-- EXISTS yields each stop at most once even when overlapping SHN buffers match
-- it multiple times (one stop can be in multiple buffers if line segments are small)
stops_on_shn AS (
    SELECT current_stops._gtfs_key
    FROM current_stops
    WHERE EXISTS (
        SELECT 1
        FROM buffer_geometry_table
        WHERE ST_DWITHIN(
            buffer_geometry_table.buffer_geometry, current_stops.pt_geom, 0
        )
    )
),

dim_stops_latest_with_shn_boolean AS (
    SELECT
        dim_stops_latest.*,
        IF(stops_on_shn._gtfs_key IS NOT NULL, TRUE, FALSE) AS on_state_highway_network
    FROM dim_stops_latest
    LEFT JOIN stops_on_shn
        ON dim_stops_latest._gtfs_key = stops_on_shn._gtfs_key
)

SELECT * FROM dim_stops_latest_with_shn_boolean
