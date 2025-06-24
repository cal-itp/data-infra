{{ config(
    materialized='table',
    partition_by={
      'field': 'year',
      'data_type': 'int64',
      "range": {
        "start": 2021,
        "end": 2030,
        "interval": 1
    }}, cluster_by=['year', 'gtfs_dataset_key'],
) }}

WITH trips AS (
    SELECT * FROM {{ ref('fct_scheduled_trips') }}
),

dim_shapes_arrays AS (
    SELECT
        key,
        pt_array
    FROM {{ ref('dim_shapes_arrays') }}
),

monthly_trips AS (

    SELECT

        gtfs_dataset_key,
        name,
        EXTRACT(month FROM service_date) AS month,
        EXTRACT(year FROM service_date) AS year,
        CASE
            WHEN EXTRACT(DAYOFWEEK FROM service_date) = 1 THEN "Sunday"
            WHEN EXTRACT(DAYOFWEEK FROM service_date) = 7 THEN "Saturday"
            ELSE "Weekday"
        END
        AS day_type,
        time_of_day,
        --route_id, # this might change over longer time periods
        direction_id,
        route_short_name,
        route_long_name,
        CONCAT(COALESCE(trips.route_short_name, ""), ' ', COALESCE(trips.route_long_name, "")) AS route_name,
        route_desc,
        route_color,
        route_text_color,
        trip_id,
        shape_id,
        shape_array_key,

        AVG(service_hours) AS service_hours,
        COUNT(DISTINCT trip_instance_key) as n_trips,
        COUNT(DISTINCT service_date) as n_days,

    FROM trips
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16

),

monthly_trips_with_geom AS (
    SELECT
        monthly_trips.*,
        dim_shapes_arrays.pt_array

    FROM monthly_trips
    INNER JOIN dim_shapes_arrays
        ON monthly_trips.shape_array_key = dim_shapes_arrays.key
)


SELECT * FROM monthly_trips_with_geom
