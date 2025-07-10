with transit_facilities as (
    SELECT * FROM {{ ref('transit_facilities') }}
),
stg_transit_database__transit_facilities AS (
    SELECT
        id,
        agency_name,
        facility_id,
        facility_name,
        facility_type,
        ntd_id,
        ST_GEOGFROMGEOJSON(geojson_geometry) AS geometry -- Convert string to GEOGRAPHY
    FROM
        transit_facilities
)
SELECT * FROM stg_transit_database__transit_facilities
