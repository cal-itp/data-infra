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


next_location AS (
    SELECT
        key AS next_location_key,
        location AS next_location,
    FROM fct_vehicle_locations
),

same_locations AS (
    SELECT
        fct_vehicle_locations.key,
        fct_vehicle_locations.next_location_key,
        ST_X(fct_vehicle_locations.location) AS lon,
        ST_Y(fct_vehicle_locations.location) AS lat,
        ST_X(next_location.next_location) - ST_X(fct_vehicle_locations.location) AS delta_lon,
        ST_Y(next_location.next_location) - ST_Y(fct_vehicle_locations.location) AS delta_lat,
        CASE
            WHEN ST_EQUALS(fct_vehicle_locations.location, next_location.next_location)
            THEN 0
            ELSE 1
        END AS new_group,
    FROM fct_vehicle_locations
    INNER JOIN next_location
        ON fct_vehicle_locations.next_location_key = next_location.next_location_key
),

direction AS (
    SELECT
        same_locations.key,
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
        END AS vp_direction_current_to_next,
        same_locations.new_group,
    FROM same_locations
    -- subset to where new_group is identified so we can fill in unknown
    -- direction / dwelling points once we group the vp
),

keys_grouped AS (
    SELECT
        fct_vehicle_locations.trip_instance_key,
        fct_vehicle_locations.key,
        fct_vehicle_locations.location_timestamp,
        fct_vehicle_locations.location,
        fct_vehicle_locations.next_location_key,
        COALESCE(direction.new_group, 1) AS new_group,
        direction.vp_direction_current_to_next,
    FROM fct_vehicle_locations
    LEFT JOIN direction
        ON fct_vehicle_locations.key = direction.key
),


vp_grouper AS (
    SELECT
        keys_grouped.key,
        keys_grouped.location,
        keys_grouped.location_timestamp,
        keys_grouped.next_location_key,
        SUM(keys_grouped.new_group)
            OVER (
                PARTITION BY trip_instance_key
                ORDER BY location_timestamp
                RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            )  AS vp_group,
        COALESCE(keys_grouped.vp_direction_current_to_next, "Unknown") AS vp_direction, -- there can be missing, infrequent though
    FROM keys_grouped
)

SELECT * FROM vp_grouper ORDER BY location_timestamp
