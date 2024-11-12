WITH external_state_geoportal__state_highway_network AS (
    SELECT *
    FROM
    {{ source('external_state_geoportal', 'state_highway_network') }}
),

get_latest_extract AS(

    SELECT *
    FROM external_state_geoportal__state_highway_network
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

buffer_geometry_table AS (
    SELECT
        ST_BUFFER(wkt_coordinates,
            30.48) AS buffer_geometry
    FROM get_latest_extract
),

current_stops AS (
    SELECT
        pt_geom,
        key
    FROM {{ ref('dim_stops_latest') }}
),


stops_on_shn AS (
    SELECT
        current_stops.*
    FROM buffer_geometry_table, current_stops
    WHERE ST_DWITHIN(
            buffer_geometry_table.buffer_geometry,current_stops.pt_geom, 0)
),

stg_state_geoportal__state_highway_network_stops AS (
    SELECT *
    FROM stops_on_shn
)

SELECT * FROM stg_state_geoportal__state_highway_network_stops
