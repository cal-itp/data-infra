{{ config(materialized='table') }}

WITH dim_gtfs_datasets AS (
    SELECT * FROM {{ ref('dim_gtfs_datasets') }}
),

fct_scheduled_trips AS (
    SELECT *
    FROM {{ ref('fct_scheduled_trips') }}
    WHERE service_date >= '2023-06-01' AND service_date < '2023-07-01'
),

fct_daily_scheduled_shapes AS (

    SELECT
        shape_array_key,
        pt_array

    FROM {{ ref('fct_daily_scheduled_shapes') }}
    WHERE service_date >= '2023-06-01' AND service_date < '2023-07-01'
),

extract_trip_date_types AS (

    SELECT
        gtfs_dataset_key,
        route_id,
        shape_id,
        shape_array_key,
        direction_id,
        EXTRACT(month FROM service_date) AS month,
        EXTRACT(year FROM service_date) AS year,

        COUNT(*) AS n_trips,

    FROM fct_scheduled_trips
    GROUP BY 1, 2, 3, 4, 5, 6, 7
),

trip_aggregations AS (
    SELECT
        gtfs_dataset_key,
        route_id,
        shape_id,
        shape_array_key,
        direction_id,
        month,
        year,

    FROM extract_trip_date_types
    QUALIFY ROW_NUMBER() OVER (PARTITION BY
                               gtfs_dataset_key, route_id,
                               shape_id, shape_array_key,
                               direction_id,
                               month, year
                               ORDER BY n_trips) = 1

),

fct_daily_scheduled_shapes_monthly_aggregations AS (

    SELECT
        dim_gtfs_datasets.name,
        dim_gtfs_datasets.source_record_id,

        trips.route_id,
        trips.shape_id,
        trips.direction_id,
        trips.month,
        trips.year,
        trips.n_trips,

        shapes.pt_array

    FROM trip_aggregations AS trips
    LEFT JOIN dim_gtfs_datasets
        ON (trips.gtfs_dataset_key = dim_gtfs_datasets.key)
    LEFT JOIN fct_daily_scheduled_shapes AS shapes
        ON (shapes.shape_array_key = trips.shape_array_key)
)


SELECT * FROM fct_daily_scheduled_shapes_monthly_aggregations
