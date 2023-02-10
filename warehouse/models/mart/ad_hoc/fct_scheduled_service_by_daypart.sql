{{ config(materialized='table') }}

WITH dim_shapes_arrays AS (
    SELECT * FROM {{ ref('dim_shapes_arrays') }}
),

dim_routes AS (
    SELECT * FROM {{ ref('dim_routes') }}
),

dim_gtfs_datasets AS (
    SELECT * FROM {{ ref('dim_gtfs_datasets') }}
),

fct_daily_scheduled_trips AS (
    SELECT *
    FROM {{ ref('fct_daily_scheduled_trips') }}
    WHERE activity_date >= '2022-12-01' AND activity_date < '2023-01-01'
),

extract_trip_date_types AS (

    SELECT
        *,

        CASE
            WHEN EXTRACT(hour FROM activity_first_departure) < 4 THEN "OWL"
            WHEN EXTRACT(hour FROM activity_first_departure) < 7 THEN "Early AM"
            WHEN EXTRACT(hour FROM activity_first_departure) < 10 THEN "AM Peak"
            WHEN EXTRACT(hour FROM activity_first_departure) < 15 THEN "Midday"
            WHEN EXTRACT(hour FROM activity_first_departure) < 20 THEN "PM Peak"
            ELSE "Evening"
        END
        AS time_of_day,

        EXTRACT(month FROM activity_date) AS month,
        EXTRACT(year FROM activity_date) AS year,
        EXTRACT(DAYOFWEEK from activity_date) AS day_type

    FROM fct_daily_scheduled_trips

),

daily_routes_and_shapes AS (
    SELECT

        dim_gtfs_datasets.name,
        dim_gtfs_datasets.source_record_id,

        trips.time_of_day,
        trips.month,
        trips.year,
        trips.day_type,

        shapes.shape_id,

        routes.route_id,
        routes.route_short_name,
        routes.base64_url

    FROM extract_trip_date_types AS trips
    INNER JOIN dim_routes AS routes
        ON (trips.feed_key = routes.feed_key)
            AND (trips.route_id = routes.route_id)
    LEFT JOIN dim_shapes_arrays AS shapes
        ON (trips.feed_key = shapes.feed_key)
            AND (trips.shape_id = shapes.shape_id)
    LEFT JOIN dim_gtfs_datasets
        ON (routes.base64_url = dim_gtfs_datasets.base64_url)

),

count_day_parts AS (
    SELECT

        name,
        source_record_id,
        time_of_day,
        month,
        year,
        day_type,
        shape_id,
        route_id,
        route_short_name,
        base64_url,

        COUNT(*) AS n

    FROM daily_routes_and_shapes
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
),

fct_scheduled_service_by_daypart AS (
    SELECT *
    FROM count_day_parts
)

SELECT * FROM fct_scheduled_service_by_daypart
