{{ config(materialized='table') }}

WITH dim_gtfs_datasets AS (
    SELECT *
    FROM {{ ref('dim_gtfs_datasets') }}
),

fct_scheduled_trips AS (
    SELECT *
    FROM {{ ref('fct_scheduled_trips') }}
    #WHERE service_date < CURRENT_DATE()
    WHERE service_date >= '2023-06-01' AND service_date < '2023-06-03'
),

dim_shapes_arrays AS (

    SELECT
        key,
        base64_url,
        shape_id,
        pt_array

    FROM {{ ref('dim_shapes_arrays') }}
    WHERE {{ incremental_where(default_start_var='GTFS_SCHEDULE_START',
                               this_dt_column='_feed_valid_from',
                               filter_dt_column='_feed_valid_from',
                               dev_lookback_days = None)
           }}
),

trips_by_shape AS (

    SELECT
        base64_url,
        route_id,
        shape_id,
        EXTRACT(month FROM service_date) AS month,
        EXTRACT(year FROM service_date) AS year,
        COUNT(*) AS n_trips,

    FROM fct_scheduled_trips
    GROUP BY 1, 2, 3, 4, 5
    QUALIFY ROW_NUMBER() OVER (PARTITION BY
                               base64_url, route_id, month, year
                               ORDER BY n_trips DESC) = 1
),

fct_monthly_shapes AS (

    SELECT
        dim_gtfs_datasets.source_record_id,
        dim_gtfs_datasets.name,

        trips.base64_url,
        trips.route_id,
        trips.shape_id,
        trips.month,
        trips.year,

        shapes.key AS shape_array_key,
        shapes.pt_array

    FROM trips_by_shape AS trips
    INNER JOIN dim_gtfs_datasets
        ON trips.base64_url = dim_gtfs_datasets.base64_url
    INNER JOIN dim_shapes_arrays AS shapes
        ON trips.base64_url = shapes.base64_url
        AND trips.shape_id = shapes.shape_id
)

SELECT * FROM fct_monthly_shapes
