{{ config(materialized='table') }}

WITH fct_vehicle_locations AS (
    SELECT
        trip_instance_key,
        key,
        location_timestamp,
        location,
        next_location_key,
    FROM cal-itp-data-infra-staging.tiffany_mart_gtfs.culver_trip
    ORDER by trip_instance_key, location_timestamp
),


lat_lon AS (
    SELECT
        fct_vehicle_locations.trip_instance_key,
        fct_vehicle_locations.key,
        fct_vehicle_locations.location_timestamp,
        ST_X(fct_vehicle_locations.location) AS lon,
        ST_Y(fct_vehicle_locations.location) AS lat,
    FROM fct_vehicle_locations

),

grouped AS (
    SELECT
        key,
        location_timestamp,
        LAG(lon, 1, NULL)
            OVER (PARTITION BY trip_instance_key
                  ORDER BY location_timestamp)
        AS prev_lon,
        LAG(lat, 1, NULL)
            OVER (PARTITION BY trip_instance_key
                  ORDER BY location_timestamp)
        AS prev_lat,
    FROM lat_lon
)


SELECT * FROM grouped
