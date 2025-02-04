{{
    config(
        materialized='incremental',
        incremental_strategy='insert_overwrite',
        partition_by = {
            'field': 'dt',
            'data_type': 'date',
            'granularity': 'day',
        },
        cluster_by=['dt', 'base64_url'],
        on_schema_change='append_new_columns'
    )
}}

WITH fct_vehicle_locations AS (
    SELECT
        key,
        dt,
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
    WHERE {{ incremental_where(default_start_var='PROD_GTFS_RT_START') }}
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
        same_locations.next_location_key AS key,
        same_locations.new_group,
        CASE
            WHEN (ABS(delta_lon) > ABS(delta_lat)) AND (delta_lon > 0)
            THEN "East"
            WHEN (ABS(delta_lon) > ABS(delta_lat)) AND (delta_lon < 0)
            THEN "West"
            WHEN (ABS(delta_lon) < ABS(delta_lat)) AND (delta_lat > 0)
            THEN "North"
            WHEN (ABS(delta_lon) < ABS(delta_lat)) AND (delta_lat < 0)
            THEN "South"
        END AS vp_direction,
    FROM same_locations
    WHERE same_locations.new_group = 1
    -- subset to where new_group is identified so we can fill in unknown
    -- direction / dwelling points once we group the vp
),

keys_grouped AS (
    SELECT
        fct_vehicle_locations.key,
        direction.new_group,
        direction.vp_direction
    FROM fct_vehicle_locations
    LEFT JOIN direction
        ON fct_vehicle_locations.key = direction.key
),

vp_grouper AS (
    SELECT
        fct_vehicle_locations.key,
        fct_vehicle_locations.dt,
        fct_vehicle_locations.gtfs_dataset_key,
        fct_vehicle_locations.base64_url,
        fct_vehicle_locations.gtfs_dataset_name,
        fct_vehicle_locations.schedule_gtfs_dataset_key,
        fct_vehicle_locations.service_date,
        fct_vehicle_locations.trip_instance_key,
        fct_vehicle_locations.location,
        fct_vehicle_locations.location_timestamp,
        SUM(keys_grouped.new_group)
            OVER (
                PARTITION BY service_date, trip_instance_key
                ORDER BY location_timestamp
                RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            )  AS vp_group,
        keys_grouped.vp_direction
    FROM fct_vehicle_locations
    INNER JOIN keys_grouped
        ON fct_vehicle_locations.key = keys_grouped.key
),

fct_grouped_locations AS (
    SELECT
        MIN(vp_grouper.key) AS key,
        vp_grouper.dt,
        vp_grouper.gtfs_dataset_key,
        vp_grouper.base64_url,
        vp_grouper.gtfs_dataset_name,
        vp_grouper.schedule_gtfs_dataset_key,
        vp_grouper.service_date,
        vp_grouper.trip_instance_key,
        MIN(vp_grouper.location_timestamp) AS location_timestamp,
        MAX(vp_grouper.location_timestamp) AS moving_timestamp,
        COUNT(*) AS n_vp,
        ST_GEOGFROMTEXT(MIN(ST_ASTEXT(vp_grouper.location))) AS location,
        CASE
            WHEN MIN(vp_grouper.vp_direction) IS NULL
            THEN "Unknown" -- now that we grabbed a valid direction, any remaining should be unknown
            ELSE MIN(vp_grouper.vp_direction)
        END AS vp_direction,
    FROM vp_grouper
    GROUP BY dt, gtfs_dataset_key, base64_url, gtfs_dataset_name, schedule_gtfs_dataset_key, service_date, trip_instance_key, vp_group
)

SELECT * FROM fct_grouped_locations
