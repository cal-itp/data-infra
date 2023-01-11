{{ config(materialized='table') }}

WITH fct_daily_scheduled_trips AS (

    SELECT *
    FROM {{ ref('fct_daily_scheduled_trips') }}

),

dim_shapes_arrays AS (
    SELECT *
    FROM {{ ref('dim_shapes_arrays') }}
),

trips_counted AS (

    SELECT

        COUNT(DISTINCT trip_key) AS n_trips,
        feed_key,
        service_date,
        shape_id,
        shape_array_key,

        LOGICAL_OR(
            contains_warning_duplicate_trip_primary_key
        ) AS contains_warning_duplicate_trip_primary_key

    FROM fct_daily_scheduled_trips
    WHERE shape_id IS NOT NULL
    GROUP BY feed_key, service_date, shape_id, shape_array_key

),

fct_daily_scheduled_shapes AS (

    SELECT

        {{ dbt_utils.surrogate_key(['trips_counted.service_date', 'trips_counted.shape_id', 'trips_counted.shape_array_key']) }} AS key,

        trips_counted.n_trips,
        trips_counted.feed_key,
        trips_counted.service_date,
        trips_counted.shape_id,
        trips_counted.shape_array_key,

        trips_counted.contains_warning_duplicate_trip_primary_key,

        dim_shapes_arrays.pt_array

    FROM trips_counted
    LEFT JOIN dim_shapes_arrays
        ON trips_counted.shape_array_key = dim_shapes_arrays.key
)

SELECT * FROM fct_daily_scheduled_shapes
