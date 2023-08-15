{{ config(materialized='table') }}

WITH
-- because we want to guarantee a mapping to a GTFS dataset based on the last day of the month
-- use this model for mapping (rather than dim gtfs datasets directly) because it handles deletions/changes
int_transit_database__urls_to_gtfs_datasets AS (
    SELECT *
    FROM {{ ref('int_transit_database__urls_to_gtfs_datasets') }}
),

-- keep feeds that are active at the end of the month
fct_daily_schedule_feeds AS (
    SELECT
        feed_key,
        base64_url,
        gtfs_dataset_key,
        LAST_DAY(date, MONTH) as month_last_day
    FROM {{ ref('fct_daily_schedule_feeds') }}
    WHERE date = LAST_DAY(date, MONTH)
),

fct_scheduled_trips AS (
    SELECT *
    FROM {{ ref('fct_scheduled_trips') }}
    -- some trips don't have route; this is not supposed to happen but it does
    WHERE route_id IS NOT NULL
),

dim_shapes_arrays AS (

    SELECT
        feed_key,
        shape_id,
        pt_array,

    FROM {{ ref('dim_shapes_arrays') }}
),

trips_by_route_shape AS (
    SELECT
        trips.base64_url,
        trips.route_id,
        trips.shape_id,
        EXTRACT(month FROM service_date) AS month,
        EXTRACT(year FROM service_date) AS year,
        LAST_DAY(service_date, MONTH) AS month_last_day,
        COUNT(*) AS n_trips,

    FROM fct_scheduled_trips AS trips
    GROUP BY 1, 2, 3, 4, 5, 6
    QUALIFY ROW_NUMBER() OVER (PARTITION BY
                               base64_url, route_id, month_last_day
                               ORDER BY n_trips DESC) = 1
),

fct_monthly_routes AS (

    SELECT
        {{ dbt_utils.generate_surrogate_key([
            'trips.base64_url', 'trips.route_id',
            'trips.month', 'trips.year']) }} AS key,

        gtfs.source_record_id,
        gtfs.gtfs_dataset_name AS name,
        trips.base64_url,
        trips.route_id,
        trips.shape_id,
        trips.month,
        trips.year,
        trips.month_last_day,

        shapes.pt_array

    FROM trips_by_route_shape AS trips
    LEFT JOIN fct_daily_schedule_feeds AS feeds
        ON trips.base64_url = feeds.base64_url
        AND trips.month_last_day = feeds.month_last_day
    LEFT JOIN int_transit_database__urls_to_gtfs_datasets AS gtfs
        ON trips.base64_url = gtfs.base64_url
        AND CAST(trips.month_last_day AS TIMESTAMP) BETWEEN gtfs._valid_from AND gtfs._valid_to
    LEFT JOIN dim_shapes_arrays AS shapes
        ON feeds.feed_key = shapes.feed_key
        AND trips.shape_id = shapes.shape_id
    WHERE trips.month_last_day <= CURRENT_DATE()
)


SELECT * FROM fct_monthly_routes
