{{ config(materialized='table') }}

WITH dim_gtfs_datasets AS (
    SELECT *
    FROM {{ ref('dim_gtfs_datasets') }}
),

-- keep feeds that are active at the end of the month
fct_daily_schedule_feeds AS (
    SELECT
        feed_key,
        base64_url,
        LAST_DAY(date, MONTH) as month_last_day
    FROM {{ ref('fct_daily_schedule_feeds') }}
    WHERE date = LAST_DAY(date, MONTH)
),

fct_scheduled_trips AS (
    SELECT *
    FROM {{ ref('fct_scheduled_trips') }}
),

dim_shapes_arrays AS (

    SELECT
        feed_key,
        shape_id,
        pt_array,

    FROM {{ ref('dim_shapes_arrays') }}
),

trips_by_route AS (

    SELECT

        dim_gtfs_datasets.source_record_id,
        dim_gtfs_datasets.name,

        trips.base64_url,
        trips.route_id,
        trips.shape_id,
        EXTRACT(month FROM service_date) AS month,
        EXTRACT(year FROM service_date) AS year,
        LAST_DAY(service_date, MONTH) AS month_last_day,
        COUNT(*) AS n_trips,

    FROM fct_scheduled_trips AS trips
    LEFT JOIN dim_gtfs_datasets
        ON trips.gtfs_dataset_key = dim_gtfs_datasets.key
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
    QUALIFY ROW_NUMBER() OVER (PARTITION BY
                               source_record_id, route_id, month_last_day
                               ORDER BY n_trips DESC) = 1
),

fct_monthly_routes AS (

    SELECT
        {{ dbt_utils.generate_surrogate_key([
            'trips.base64_url', 'trips.route_id',
            'trips.month', 'trips.year']) }} AS key,

        trips.source_record_id,
        trips.name,
        trips.base64_url,
        trips.route_id,
        trips.shape_id,
        trips.month,
        trips.year,

        shapes.pt_array

    FROM trips_by_route AS trips
    LEFT JOIN fct_daily_schedule_feeds AS feeds
        ON trips.base64_url = feeds.base64_url
        AND trips.month_last_day = feeds.month_last_day
    LEFT JOIN dim_shapes_arrays AS shapes
        ON feeds.feed_key = shapes.feed_key
        AND trips.shape_id = shapes.shape_id
    WHERE trips.month_last_day <= CURRENT_DATE()
)


SELECT * FROM fct_monthly_routes
