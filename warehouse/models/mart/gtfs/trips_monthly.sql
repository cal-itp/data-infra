{{ config(materialized='table') }}


WITH trips AS (
    SELECT
        *
    --FROM {{ ref('fct_scheduled_trips') }}
    FROM `cal-itp-data-infra.mart_gtfs.fct_scheduled_trips`
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
        -- fix Metrolink's empty shape_ids based on route_id and direction_id
        -- based on https://github.com/cal-itp/data-analyses/blob/main/_shared_utils/shared_utils/gtfs_utils_v2.py#L153-L228
        CASE
            WHEN trips.route_id = "Antelope Valley Line" AND trips.direction_id = 0 THEN "AVout"
            WHEN trips.route_id = "Antelope Valley Line" AND trips.direction_id = 1 THEN "AVin"
            WHEN trips.route_id = "Orange County Line" AND trips.direction_id = 0 THEN "OCout"
            WHEN trips.route_id = "Orange County Line" AND trips.direction_id = 1 THEN "OCin"
            WHEN trips.route_id = "LAX FlyAway Bus" AND trips.direction_id = 0 THEN "LAXout"
            WHEN trips.route_id = "LAX FlyAway Bus" AND trips.direction_id = 1 THEN "LAXin"
            WHEN trips.route_id = "San Bernardino Line" AND trips.direction_id = 0 THEN "SBout"
            WHEN trips.route_id = "San Bernardino Line" AND trips.direction_id = 1 THEN "SBin"
            WHEN trips.route_id = "Ventura County Line" AND trips.direction_id = 0 THEN "VTout"
            WHEN trips.route_id = "Ventura County Line" AND trips.direction_id = 1 THEN "VTin"
            WHEN trips.route_id = "91 Line" AND trips.direction_id = 0 THEN "91out"
            WHEN trips.route_id = "91 Line" AND trips.direction_id = 1 THEN "91in"
            WHEN trips.route_id = "Inland Emp.-Orange Co. Line" AND trips.direction_id = 0 THEN "IEOCout"
            WHEN trips.route_id = "Inland Emp.-Orange Co. Line" AND trips.direction_id = 1 THEN "IEOCin"
            WHEN trips.route_id = "Riverside Line" AND trips.direction_id = 0 THEN "RIVERout"
            WHEN trips.route_id = "Riverside Line" AND trips.direction_id = 1 THEN "RIVERin"
            ELSE trips.shape_id
        END
        AS shape_id,
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
