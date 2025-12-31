{{ config(materialized='table') }}

WITH fct_scheduled_trips AS (
    SELECT * FROM {{ ref('fct_monthly_scheduled_trips') }}
),

dim_shapes_arrays AS (
    SELECT
        key,
        pt_array
    FROM {{ ref('dim_shapes_arrays') }}
),

trip_counts AS (
    SELECT
        name,
        year,
        month,
        month_first_day,
        route_name,
        direction_id,
        route_type,
        shape_id,
        shape_array_key,

        COUNT(*) AS n_trips,

    FROM fct_scheduled_trips
    GROUP BY name, year, month, month_first_day, route_name, direction_id, route_type, shape_id, shape_array_key
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY
            name, year, month, month_first_day, route_name, direction_id, route_type
        ORDER BY n_trips DESC) = 1
),

fct_monthly_routes AS (
    SELECT
        trip_counts.*,
        dim_shapes_arrays.pt_array
    FROM trip_counts
    INNER JOIN dim_shapes_arrays
        ON dim_shapes_arrays.key = trip_counts.shape_array_key
)

SELECT * FROM fct_monthly_routes
