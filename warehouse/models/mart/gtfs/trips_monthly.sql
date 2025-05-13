{{ config(materialized='table') }}


WITH trips AS (
    SELECT
        *
    FROM {{ ref('fct_scheduled_trips') }}
    --FROM `cal-itp-data-infra.mart_gtfs.fct_scheduled_trips`
    --WHERE EXTRACT(YEAR FROM service_date) >= 2024
),

day_of_week AS (
    SELECT
        gtfs_dataset_key,
        service_date,
        EXTRACT(MONTH FROM service_date) AS month,
        EXTRACT(YEAR FROM service_date) AS year,
        CASE
            WHEN EXTRACT(DAYOFWEEK FROM service_date) = 1 THEN "Sunday"
            WHEN EXTRACT(DAYOFWEEK FROM service_date) = 7 THEN "Saturday"
            ELSE "Weekday"
        END
        AS day_type,
    FROM fct_scheduled_trips
    GROUP BY gtfs_dataset_key, service_date
),

fct_monthly_trips AS (
    SELECT
        trips.gtfs_dataset_key,
        trips.base64_url,
        trips.name,
        day_of_week.year,
        day_of_week.month,
        day_of_week.day_type,
        trips.trip_id,
        trips.route_id,
        trips.direction_id,
        trips.shape_id,
        trips.route_short_name,
        trips.route_long_name,
        COUNT(trips.service_date) AS n_days,
    FROM trips
    INNER JOIN day_of_week
        ON trips.gtfs_dataset_key = day_of_week.gtfs_dataset_key AND trips.service_date = day_of_week.service_date
    GROUP BY gtfs_dataset_key, base64_url, name,
        year, month, day_type,
        trip_id,
        route_id, direction_id, shape_id,
        route_short_name, route_long_name
)

SELECT * FROM fct_monthly_trips
