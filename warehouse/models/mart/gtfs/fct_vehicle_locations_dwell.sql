{{ config(materialized='table') }}

WITH fct_vehicle_locations AS (
    SELECT
        key,
        --gtfs_dataset_key,
        --dt,
        service_date,
        --base64_url,
        --gtfs_dataset_name,
        --schedule_gtfs_dataset_key,
        trip_instance_key,
        location_timestamp,
        location,
        next_location_key,

    FROM {{ ref('fct_vehicle_locations') }}
    WHERE gtfs_dataset_name="LA DOT VehiclePositions" AND trip_instance_key="0000a63ce280462e6eed4f3ae92df16d" AND service_date = "2025-01-07"
    ORDER by service_date, trip_instance_key, location_timestamp
    ),

current_vp AS (
    SELECT
        service_date,
        trip_instance_key,
        key,
        location,
        location_timestamp,
        next_location_key,
    FROM fct_vehicle_locations
),

get_next AS (
    SELECT
        key AS next_location_key,
        location,
        location_timestamp
    FROM current_vp
),

vp_groupings AS (
    SELECT
        current_vp.service_date,
        current_vp.trip_instance_key,
        current_vp.key,
        current_vp.location_timestamp,
        get_next.location_timestamp AS next_location_timestamp,
        ST_X(current_vp.location) AS current_longitude,
        ST_Y(current_vp.location) AS current_latitude,
        ST_X(get_next.location) AS next_longitude,
        ST_Y(get_next.location) AS next_latitude,
    FROM current_vp
    LEFT JOIN get_next
        ON current_vp.next_location_key = get_next.next_location_key
),

vp_grouping_agg AS (
    SELECT
        vp_groupings.service_date,
        vp_groupings.trip_instance_key,
        vp_groupings.key,
        vp_groupings.location_timestamp,
        vp_groupings.current_longitude,
        vp_groupings.next_longitude,
        vp_groupings.current_latitude,
        vp_groupings.next_latitude,
        CASE
            WHEN current_longitude = next_longitude AND current_latitude = next_latitude
            THEN 0
            ELSE 1
        END AS new_group,
    FROM vp_groupings
),

vp_grouping_agg2 AS (
    SELECT
        key,
        SUM(new_group)
            OVER (
                PARTITION BY service_date, trip_instance_key
                ORDER BY location_timestamp
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            )  AS vp_group,
    FROM vp_grouping_agg
)


SELECT * FROM vp_grouping_agg2
