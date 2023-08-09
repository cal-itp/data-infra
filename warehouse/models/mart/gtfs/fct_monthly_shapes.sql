{{ config(materialized='table') }}

WITH dim_gtfs_datasets AS (
    SELECT *
    FROM {{ ref('dim_gtfs_datasets') }}
),

fct_scheduled_trips AS (
    SELECT *
    FROM {{ ref('fct_scheduled_trips') }}
    WHERE service_date >= '2023-06-01'
),

dim_shapes_arrays AS (

    SELECT
        base64_url,
        shape_id,
        pt_array,
        _feed_valid_from

    FROM {{ ref('dim_shapes_arrays') }}
    WHERE {{ incremental_where(default_start_var='GTFS_SCHEDULE_START',
                               this_dt_column='month_last_day',
                               filter_dt_column='_feed_valid_from',
                               dev_lookback_days = None)
           }}
    -- keep most recent feed's shape_id pt_array if multiple versions are stored
    QUALIFY ROW_NUMBER() OVER (PARTITION BY
                               base64_url, shape_id
                               ORDER BY _feed_valid_from DESC) = 1
),

trips_by_shape AS (

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

    FROM fct_scheduled_trips as trips
    LEFT JOIN dim_gtfs_datasets
        ON trips.gtfs_dataset_key = dim_gtfs_datasets.key
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
    QUALIFY ROW_NUMBER() OVER (PARTITION BY
                               source_record_id, route_id, month_last_day
                               ORDER BY n_trips DESC) = 1
),

fct_monthly_shapes AS (

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

    FROM trips_by_shape AS trips
    INNER JOIN dim_shapes_arrays AS shapes
        ON trips.base64_url = shapes.base64_url
        AND trips.shape_id = shapes.shape_id
    WHERE trips.month_last_day <= CURRENT_DATE()
)

SELECT * FROM fct_monthly_shapes
