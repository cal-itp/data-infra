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
        ST_X(fct_vehicle_locations.location) AS longitude,
        ST_Y(fct_vehicle_locations.location) AS latitude,
    FROM fct_vehicle_locations

),

lagged AS (
    SELECT
        lat_lon.trip_instance_key,
        lat_lon.key,
        lat_lon.longitude,
        lat_lon.latitude,
        lat_lon.location_timestamp,
        LAG(longitude, 1, NULL)
            OVER (PARTITION BY trip_instance_key
                  ORDER BY location_timestamp)
        AS previous_longitude,
        LAG(latitude, 1, NULL)
            OVER (PARTITION BY trip_instance_key
                  ORDER BY location_timestamp)
        AS previous_latitude,
    FROM lat_lon
),

deltas AS (
    SELECT
        lagged.key,
        lagged.trip_instance_key,
        lagged.location_timestamp,
        lagged.longitude,
        lagged.latitude,
        lagged.longitude - lagged.previous_longitude AS delta_lon,
        lagged.latitude - lagged.previous_latitude AS delta_lat,
    FROM lagged
),

direction AS (
    SELECT
        deltas.*,
        CASE
            WHEN (ABS(delta_lon) > ABS(delta_lat)) AND (delta_lon > 0)
            THEN "East"
            WHEN (ABS(delta_lon) > ABS(delta_lat)) AND (delta_lon < 0)
            THEN "West"
            WHEN (ABS(delta_lon) <= ABS(delta_lat)) AND (delta_lat > 0)
            THEN "North"
            WHEN (ABS(delta_lon) <= ABS(delta_lat)) AND (delta_lat < 0)
            THEN "South"
            WHEN (delta_lon = delta_lat) AND (delta_lat = 0)
            THEN "Unknown"
            WHEN delta_lon IS NULL OR delta_lat IS NULL
            THEN "Unknown"
        END AS vp_direction,
        CASE
            WHEN delta_lon = delta_lat AND delta_lat = 0
            THEN 0
            WHEN delta_lon IS NULL OR delta_lat IS NULL
            THEN 0
            ELSE 1
        END AS new_group,
    FROM deltas
),

vp_grouper AS (
    SELECT
        direction.trip_instance_key,
        direction.key,
        direction.location_timestamp,
        direction.longitude,
        direction.latitude,
        SUM(direction.new_group)
            OVER (
                PARTITION BY trip_instance_key
                ORDER BY location_timestamp
                RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            )  AS vp_group,
        direction.vp_direction,
    FROM direction
),

fct_grouped_locations AS (
    SELECT
        MIN(vp_grouper.key) AS key,
        vp_grouper.trip_instance_key,
        MIN(vp_grouper.location_timestamp) AS location_timestamp,
        MAX(vp_grouper.location_timestamp) AS moving_timestamp,
        ST_GEOGPOINT(vp_grouper.longitude, vp_grouper.latitude) AS location,
        COUNT(*) AS n_vp,
        MIN(vp_grouper.vp_direction) AS vp_direction,
        vp_group,
    FROM vp_grouper
    GROUP BY trip_instance_key, vp_group, longitude, latitude
)

SELECT * FROM fct_grouped_locations ORDER BY location_timestamp
