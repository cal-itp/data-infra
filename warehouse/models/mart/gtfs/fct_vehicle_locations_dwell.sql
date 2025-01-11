{{ config(materialized='table') }}

WITH fct_vehicle_locations AS (
    SELECT
        key,
        service_date,
        trip_instance_key,
        location_timestamp,
        location,
        next_location_key,

    FROM {{ ref('fct_vehicle_locations') }}
    WHERE gtfs_dataset_name="LA DOT VehiclePositions" AND service_date = "2025-01-07" AND (trip_instance_key="0000a63ce280462e6eed4f3ae92df16d" OR trip_instance_key="ec14aa25e209f90ed025450c18519814")
    ORDER by service_date, trip_instance_key, location_timestamp
    ),


get_next AS (
    SELECT
        key AS next_location_key,
        location,
        location_timestamp
    FROM fct_vehicle_locations
),

vp_groupings AS (
    SELECT
        fct_vehicle_locations.service_date,
        fct_vehicle_locations.trip_instance_key,
        fct_vehicle_locations.key,
        --fct_vehicle_locations.location,
        fct_vehicle_locations.location_timestamp,
        get_next.location_timestamp AS next_location_timestamp,
        --get_next.location AS next_location,
        CASE
            WHEN ST_EQUALS(fct_vehicle_locations.location, get_next.location)
            THEN 0
            ELSE 1
        END AS new_group,
    FROM fct_vehicle_locations
    LEFT JOIN get_next
        ON fct_vehicle_locations.next_location_key = get_next.next_location_key
),

grouped AS (
    SELECT
        key,
        SUM(new_group)
            OVER (
                PARTITION BY service_date, trip_instance_key
                ORDER BY location_timestamp
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            )  AS vp_group,
    FROM vp_groupings
),

merged AS (
    SELECT
        fct_vehicle_locations.trip_instance_key AS trip_instance_key,
        fct_vehicle_locations.service_date AS service_date,
        MIN(fct_vehicle_locations.key) AS key,
        grouped.vp_group AS vp_group,
        COUNT(*) AS n_vp,
        MIN(fct_vehicle_locations.location_timestamp) AS location_timestamp,
        MAX(fct_vehicle_locations.location_timestamp) AS moving_timestamp,
    FROM fct_vehicle_locations
    LEFT JOIN grouped
        ON fct_vehicle_locations.key = grouped.key
    GROUP BY service_date, trip_instance_key, vp_group
),

fct_vehicle_locations_dwell AS (
    SELECT
        merged.trip_instance_key AS trip_instance_key,
        merged.service_date AS service_date,
        merged.key AS key,
        merged.vp_group as vp_group, -- this column can be deleted, but use this to check, because vp_group=11 should have 2, but sometimes has count of 1.
        merged.n_vp as n_vp,
        merged.location_timestamp AS location_timestamp,
        merged.moving_timestamp AS moving_timestamp,
        fct_vehicle_locations.location AS location
    FROM merged
    LEFT JOIN fct_vehicle_locations
        ON merged.key = fct_vehicle_locations.key
)

-- can we roll in n_vp + location into merged
-- without the last merge? how to group with location (geography) type?
-- expect to see n_vp have values 1, 2, 3 for these 2 trips

SELECT * FROM fct_vehicle_locations_dwell
