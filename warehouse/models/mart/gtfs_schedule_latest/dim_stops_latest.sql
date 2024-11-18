WITH
dim_stops_latest AS (
    {{ get_latest_schedule_data(
    table_name = ref('dim_stops'),
    clean_table_name = 'dim_stops'
    ) }}
),

stg_state_geoportal__state_highway_network_stops AS (
SELECT *
-- FROM `cal-itp-data-infra-staging.external_state_geoportal.stg_state_geoportal__state_highway_network_stops`
FROM {{ ref('stg_state_geoportal__state_highway_network_stops') }}
),


buffer_geometry_table AS (
    SELECT
        ST_BUFFER(wkt_coordinates,
            30.48) AS buffer_geometry
    FROM stg_state_geoportal__state_highway_network_stops
),

current_stops AS (
    SELECT
        pt_geom,
        stop_id
        --key
    FROM dim_stops_latest
),


stops_on_shn AS (
    SELECT
        current_stops.*
    FROM buffer_geometry_table, current_stops
    WHERE ST_DWITHIN(
            buffer_geometry_table.buffer_geometry,current_stops.pt_geom, 0)
),

dim_stops_latest_with_shn_boolean AS (

SELECT
    dim_stops_latest.*,
    IF(stops_on_shn.stop_id IS NOT NULL, TRUE, FALSE) AS exists_in_dim_stops_latest
FROM
    dim_stops_latest
LEFT JOIN
    stops_on_shn
ON
    dim_stops_latest.stop_id = stops_on_shn.stop_id
    -- dim_stops_latest.key = stops_on_shn.key
)

SELECT * FROM dim_stops_latest_with_shn_boolean
