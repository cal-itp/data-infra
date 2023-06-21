{{ config(materialized='table') }}

WITH dim_gtfs_datasets AS (
    SELECT * FROM {{ ref('dim_gtfs_datasets') }}
),

fct_scheduled_trips AS (
    SELECT *
    FROM {{ ref('fct_scheduled_trips') }}
    WHERE service_date >= '2023-06-01' AND service_date < '2023-06-04'
),

fct_daily_scheduled_shapes AS (

    SELECT
        shape_array_key,
        n_trips,
        pt_array

    FROM {{ ref('fct_daily_scheduled_shapes') }}
    WHERE service_date >= '2023-06-01' AND service_date < '2023-06-04'
),

extract_trip_date_types AS (

    SELECT DISTINCT
        gtfs_dataset_key,
        route_id,
        shape_id,
        shape_array_key,
        direction_id,
        EXTRACT(month FROM service_date) AS month,
        EXTRACT(year FROM service_date) AS year,

    FROM fct_scheduled_trips
),

trips_by_shape AS (

    SELECT

        trips.gtfs_dataset_key,
        trips.route_id,
        trips.shape_id,
        trips.shape_array_key,
        trips.direction_id,
        trips.month,
        trips.year,

        shapes.n_trips,

    FROM extract_trip_date_types AS trips
    LEFT JOIN fct_daily_scheduled_shapes AS shapes
        ON (shapes.shape_array_key = trips.shape_array_key)
),

shape_aggregations AS (

    SELECT
        gtfs_dataset_key,
        route_id,
        shape_id,
        shape_array_key,
        direction_id,
        month,
        year,

        SUM(n_trips) as n_trips,

    FROM trips_by_shape
    GROUP BY 1, 2, 3, 4, 5, 6, 7
),

fct_daily_scheduled_shapes_monthly_aggregations AS (

    SELECT
        dim_gtfs_datasets.name,
        dim_gtfs_datasets.source_record_id,

        shape_aggregations.route_id,
        shape_aggregations.shape_id,
        shape_aggregations.direction_id,
        shape_aggregations.month,
        shape_aggregations.year,
        shape_aggregations.n_trips,

        shapes.pt_array,

    FROM shape_aggregations
    LEFT JOIN dim_gtfs_datasets
        ON (shape_aggregations.gtfs_dataset_key = dim_gtfs_datasets.key)
    LEFT JOIN fct_daily_scheduled_shapes AS shapes
        ON (shapes.shape_array_key = shape_aggregations.shape_array_key)
    QUALIFY ROW_NUMBER() OVER (PARTITION BY
                               name, source_record_id, route_id, shape_id,
                               direction_id, month, year
                              ORDER BY n_trips desc) = 1
)

SELECT * FROM fct_daily_scheduled_shapes_monthly_aggregations
