{{ config(materialized='table') }}

WITH fct_daily_scheduled_trips AS (
    SELECT *
    FROM {{ ref('fct_daily_scheduled_trips') }}
    WHERE service_date >= '2022-12-01' AND service_date < '2023-01-01'
),

dim_shapes_arrays AS (
    SELECT * FROM {{ ref('dim_shapes_arrays') }}
),

dim_routes AS (
    SELECT * FROM {{ ref('dim_routes') }}
),

daily_routes_and_shapes AS (
    SELECT

        *

    FROM fct_daily_scheduled_trips AS trips
    INNER JOIN dim_routes AS routes
        ON (trips.feed_key = routes.feed_key)
            AND (trips.route_id = routes.route_id)
    LEFT JOIN dim_shapes_arrays AS shapes
        ON (trips.feed_key = shapes.feed_key)
            AND (trips.shape_id = shapes.shape_id)
),

day_part_buckets AS (
    SELECT

        *,
        CASE
            WHEN hour < 4 THEN "OWL",
            WHEN hour < 7 THEN "Early AM",
            WHEN hour < 10 THEN "AM Peak",
            WHEN hour < 15 THEN "Midday",
            WHEN hour < 20 THEN "PM Peak",
            ELSE "Evening"
        END
        AS day_part

    FROM daily_routes_and_shapes

),

count_day_parts AS (
    SELECT

        COUNT(*)

    FROM day_part_buckets
    GROUP BY 1, 2, 3, 4, 5, 6
),

fct_scheduled_service_by_daypart AS (
    SELECT

        *

    FROM count_day_parts
)

SELECT * FROM fct_scheduled_service_by_daypart
