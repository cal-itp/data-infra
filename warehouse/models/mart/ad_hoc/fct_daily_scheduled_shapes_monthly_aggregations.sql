{{ config(materialized='table') }}

WITH dim_gtfs_datasets AS (
    SELECT
        key,
        name,
        source_record_id
    FROM {{ ref('dim_gtfs_datasets') }}
),

fct_scheduled_trips AS (
    SELECT *
    FROM {{ ref('fct_scheduled_trips') }}
    #WHERE service_date < CURRENT_DATE()
    WHERE service_date >= '2023-06-01' AND service_date < '2023-06-02'
),

dim_shapes_arrays AS (

    SELECT
        base64_url,
        shape_id,
        shape_array_key,
        pt_array

    FROM {{ ref('dim_shapes_arrays') }}
    WHERE {{ incremental_where(default_start_var='GTFS_SCHEDULE_START',
                               this_dt_column='_feed_valid_from',
                               filter_dt_column='_feed_valid_from',
                               dev_lookback_days = None)
           }}
),

trips_by_shape AS (

    SELECT DISTINCT
        gtfs_dataset_key,
        base64_url,
        route_id,
        shape_id,
        COUNT(trip_id) AS n_trips,
        EXTRACT(month FROM service_date) AS month,
        EXTRACT(year FROM service_date) AS year,

    FROM fct_scheduled_trips
    QUALIFY ROW_NUMBER() OVER (PARTITION BY
                               gtfs_dataset_key, base64_url, route_id,
                               month, year,
                               ORDER BY n_trips desc) = 1
),

fct_monthly_shapes AS (

    SELECT

        dim_gtfs_datasets.source_record_id,
        dim_gtfs_datasets.name,

        trips.gtfs_dataset_key,
        trips.base64_url,
        trips.route_id,
        trips.shape_id,
        trips.month,
        trips.year,
        trips.n_trips,

        shapes.shape_array_key,
        shapes.pt_array

    FROM trips_by_shape AS trips
    LEFT JOIN dim_gtfs_datasets
        ON trips.gtfs_dataset_key = dim_gtfs_datasets.key
    INNER JOIN dim_shape_arrays AS shapes
        ON trips.base64_url = shapes.base64_url
        AND trips.shape_id = shapes.shape_id
    GROUP BY 1, 2, 4, 5, 6, 7, 8
)

SELECT * FROM fct_monthly_shapes
