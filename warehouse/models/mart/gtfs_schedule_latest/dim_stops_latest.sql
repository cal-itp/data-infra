WITH
dim_stops_latest AS (
    {{ get_latest_schedule_data(
    table_name = ref('dim_stops'),
    clean_table_name = 'dim_stops'
    ) }}
),

buffer_geometry_table AS (
    SELECT
        ST_BUFFER(geometry,
            30.48) AS buffer_geometry
    FROM {{ ref('state_highway_network') }}
),


current_stops AS (
    SELECT
        pt_geom,
        key
    FROM {{ ref('dim_stops_latest') }}
)


SELECT
    current_stops.*
FROM buffer_geometry_table, current_stops
WHERE ST_DWITHIN(
        buffer_geometry_table.buffer_geometry,current_stops.pt_geom, 0)


-- SELECT * FROM dim_stops_latest
