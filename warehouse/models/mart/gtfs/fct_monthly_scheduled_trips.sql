{{
    config(
        materialized='table',
        cluster_by=['month_first_day', 'name']
    )
}}


WITH trips AS (
    SELECT * FROM {{ ref('fct_scheduled_trips') }}
    -- only run if new month is available. select dates <= last day of prior month
    WHERE service_date <= LAST_DAY(
        DATE_SUB(CURRENT_DATE("America/Los_Angeles"), INTERVAL 1 MONTH)
    )
),

monthly_trips AS (

    SELECT

        name,

        EXTRACT(month FROM service_date) AS month,
        EXTRACT(year FROM service_date) AS year,
        DATE_TRUNC(service_date, MONTH) AS month_first_day,

        {{ generate_day_type('service_date') }} AS day_type,
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
        ARRAY_AGG(DISTINCT route_id IGNORE NULLS) AS route_id_array

    FROM trips
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17

)

SELECT * FROM monthly_trips
