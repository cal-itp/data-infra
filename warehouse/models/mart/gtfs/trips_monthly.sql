{{ config(materialized='table') }}


WITH trips AS (
    SELECT
        *
    --FROM {{ ref('fct_scheduled_trips') }}
    FROM `cal-itp-data-infra.mart_gtfs.fct_scheduled_trips`
    WHERE EXTRACT(YEAR FROM service_date) >= 2024
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
    FROM trips
    GROUP BY 1, 2
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
        trips.trip_key,
        CASE
            WHEN EXTRACT(hour FROM trips.trip_first_departure_datetime_pacific) < 4 THEN "Owl"
            WHEN EXTRACT(hour FROM trips.trip_first_departure_datetime_pacific) < 7 THEN "Early AM"
            WHEN EXTRACT(hour FROM trips.trip_first_departure_datetime_pacific) < 10 THEN "AM Peak"
            WHEN EXTRACT(hour FROM trips.trip_first_departure_datetime_pacific) < 15 THEN "Midday"
            WHEN EXTRACT(hour FROM trips.trip_first_departure_datetime_pacific) < 20 THEN "PM Peak"
            ELSE "Evening"
        END
        AS time_of_day,
        trips.route_id,
        trips.direction_id,
        trips.route_key,
        trips.route_type,
        trips.shape_id,
        trips.shape_array_key,
        trips.route_short_name,
        trips.route_long_name,
        trips.is_gtfs_flex_trip,
        trips.service_hours,
        COUNT(trips.service_date) AS n_days,
        SUM(trips.service_hours) AS ttl_service_hours,
    FROM trips
    INNER JOIN day_of_week
        ON trips.gtfs_dataset_key = day_of_week.gtfs_dataset_key AND trips.service_date = day_of_week.service_date
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19
)

SELECT * FROM fct_monthly_trips
