{{
    config(
        materialized='incremental',
        incremental_strategy='insert_overwrite',
        unique_key = "key",
        partition_by={
            'field': 'month_first_day',
            'data_type': 'date',
            'granularity': 'month'
        },
        cluster_by=['month_first_day', 'gtfs_dataset_key', 'name']
    )
}}


WITH trips AS (
    SELECT * FROM {{ ref('fct_scheduled_trips') }}
    -- only run if new month is available. select dates <= last day of prior month
    WHERE service_date >= "2024-01-01" AND service_date <= LAST_DAY(
        DATE_SUB(CURRENT_DATE("America/Los_Angeles"), INTERVAL 1 MONTH)
    )
),

monthly_trips AS (

    SELECT
        {{ dbt_utils.generate_surrogate_key(['year', 'month', 'name', 'day_type', 'trip_id', 'iteration_num']) }} AS key,
        gtfs_dataset_key,
        name,

        EXTRACT(month FROM service_date) AS month,
        EXTRACT(year FROM service_date) AS year,
        DATE_TRUNC(service_date, MONTH) AS month_first_day,

        CASE
            WHEN EXTRACT(DAYOFWEEK FROM service_date) = 1 THEN "Sunday"
            WHEN EXTRACT(DAYOFWEEK FROM service_date) = 7 THEN "Saturday"
            ELSE "Weekday"
        END
        AS day_type,
        time_of_day,
        --route_id, # this might change over longer time periods
        direction_id,
        route_short_name,
        route_long_name,
        CONCAT(COALESCE(trips.route_short_name, ""), ' ', COALESCE(trips.route_long_name, "")) AS route_name,
        route_desc,
        route_color,
        route_text_color,
        trip_id,
        iteration_num,
        shape_id,
        shape_array_key,

        AVG(service_hours) AS service_hours,
        COUNT(DISTINCT trip_instance_key) as n_trips,
        COUNT(DISTINCT service_date) as n_days,

    FROM trips
    GROUP BY 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19

)

SELECT * FROM monthly_trips
