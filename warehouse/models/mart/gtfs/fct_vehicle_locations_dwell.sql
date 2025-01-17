{{ config(materialized='table') }}

WITH fct_vehicle_locations AS (
    SELECT
        key,
        gtfs_dataset_key,
        base64_url,
        gtfs_dataset_name,
        schedule_gtfs_dataset_key,
        service_date,
        trip_instance_key,
        location_timestamp,
        location,
        next_location_key,
    FROM {{ ref('fct_vehicle_locations') }}
    WHERE gtfs_dataset_name="LA DOT VehiclePositions" AND service_date = "2025-01-07" AND (trip_instance_key="0000a63ce280462e6eed4f3ae92df16d" OR trip_instance_key="ec14aa25e209f90ed025450c18519814")
    ORDER by service_date, trip_instance_key, location_timestamp
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
        --fct_vehicle_locations.location AS location,
        --next_location.next_location AS next_location,
        ST_X(fct_vehicle_locations.location) AS lon,
        ST_Y(fct_vehicle_locations.location) AS lat,
        ST_X(next_location.next_location) - ST_X(fct_vehicle_locations.location) AS delta_lon_ew,
        ST_Y(next_location.next_location) - ST_Y(fct_vehicle_locations.location) AS delta_lat_ns,
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
        same_locations.next_location_key AS key,
        CASE
            WHEN (ABS(delta_lon_ew) > ABS(delta_lat_ns)) AND (delta_lon_ew > 0)
            THEN "East"
            WHEN (ABS(delta_lon_ew) > ABS(delta_lat_ns)) AND (delta_lon_ew < 0)
            THEN "West"
            WHEN (ABS(delta_lon_ew) < ABS(delta_lat_ns)) AND (delta_lat_ns > 0)
            THEN "North"
            WHEN (ABS(delta_lon_ew) < ABS(delta_lat_ns)) AND (delta_lat_ns < 0)
            THEN "South"
        END AS vp_direction
    FROM same_locations
),

vp_groupings AS (
    SELECT
        fct_vehicle_locations.key,
        fct_vehicle_locations.next_location_key,
        fct_vehicle_locations.service_date,
        fct_vehicle_locations.trip_instance_key,
        fct_vehicle_locations.location,
        fct_vehicle_locations.location_timestamp,
        SUM(
            COALESCE(same_locations.new_group, 1)
        )
            OVER (
                PARTITION BY service_date, trip_instance_key
                ORDER BY location_timestamp
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            )  AS vp_group,
        direction.vp_direction -- within a vp_group, we can have null (point doesn't move) and valid direction
    FROM fct_vehicle_locations
    LEFT JOIN same_locations
        ON fct_vehicle_locations.key = same_locations.key AND fct_vehicle_locations.next_location_key = same_locations.next_location_key
    INNER JOIN direction
        ON fct_vehicle_locations.key = direction.key
),

fct_dwelling_locations AS (
    SELECT
        MIN(vp_groupings.key) AS key,
        vp_groupings.service_date,
        vp_groupings.trip_instance_key,
        MIN(vp_groupings.location_timestamp) AS location_timestamp,
        MAX(vp_groupings.location_timestamp) AS moving_timestamp,
        COUNT(*) AS n_vp,
        ST_GEOGFROMTEXT(MIN(ST_ASTEXT(vp_groupings.location))) AS location,
        CASE
            WHEN MIN(vp_groupings.vp_direction) IS NULL
            THEN "Unknown" -- now that we grabbed a valid direction, any remaining should be unknown
            ELSE MIN(vp_groupings.vp_direction)
        END AS vp_direction,
        vp_group
    FROM vp_groupings
    GROUP BY service_date, trip_instance_key, vp_group
)

SELECT * FROM fct_dwelling_locations
