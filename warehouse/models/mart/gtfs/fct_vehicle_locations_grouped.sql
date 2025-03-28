{{
    config(
        materialized='incremental',
        incremental_strategy='insert_overwrite',
        partition_by = {
            'field': 'service_date',
            'data_type': 'date',
            'granularity': 'day',
        },
        cluster_by=['service_date', 'base64_url'],
        on_schema_change='append_new_columns'
    )
}}

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
        -- rather than using next_location_key, use lag to calculate direction from previous
    FROM {{ ref('fct_vehicle_locations') }}
    WHERE {{ incremental_where(default_start_var='PROD_GTFS_RT_START') }} AND trip_instance_key IS NOT NULL
),

lat_lon AS (
    SELECT
        fct_vehicle_locations.trip_instance_key,
        fct_vehicle_locations.service_date,
        fct_vehicle_locations.key,
        fct_vehicle_locations.location_timestamp,
        ST_X(fct_vehicle_locations.location) AS longitude,
        ST_Y(fct_vehicle_locations.location) AS latitude,
    FROM fct_vehicle_locations
),

lagged AS (
    SELECT
        lat_lon.*,
        LAG(longitude, 1, NULL)
            OVER (PARTITION BY service_date, trip_instance_key
                  ORDER BY location_timestamp)
        AS previous_longitude,
        LAG(latitude, 1, NULL)
            OVER (PARTITION BY service_date, trip_instance_key
                  ORDER BY location_timestamp)
        AS previous_latitude,
    FROM lat_lon
),

deltas AS (
    SELECT
        lagged.*,
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
        direction.service_date,
        direction.key,
        SUM(direction.new_group)
            OVER (
                PARTITION BY service_date, trip_instance_key
                ORDER BY location_timestamp
                RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            )  AS vp_group,
        direction.vp_direction,
    FROM direction
),

fct_grouped_locations AS (
    SELECT
        fct_vehicle_locations.gtfs_dataset_key,
        fct_vehicle_locations.base64_url,
        fct_vehicle_locations.gtfs_dataset_name,
        fct_vehicle_locations.schedule_gtfs_dataset_key,
        fct_vehicle_locations.service_date,
        vp_grouper.trip_instance_key,
        MIN(vp_grouper.key) AS key,
        MIN(fct_vehicle_locations.location_timestamp) AS location_timestamp,
        MAX(fct_vehicle_locations.location_timestamp) AS moving_timestamp,
        ST_GEOGFROMTEXT(MIN(ST_ASTEXT(fct_vehicle_locations.location))) AS location,
        COUNT(*) AS n_vp,
        MIN(vp_grouper.vp_direction) AS vp_direction,
        vp_grouper.vp_group,
    FROM vp_grouper
    INNER JOIN fct_vehicle_locations
        ON fct_vehicle_locations.key = vp_grouper.key
    GROUP BY gtfs_dataset_key, base64_url, gtfs_dataset_name, schedule_gtfs_dataset_key, service_date, trip_instance_key, vp_group, ST_ASTEXT(fct_vehicle_locations.location)
)

SELECT * FROM fct_grouped_locations
