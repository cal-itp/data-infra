{{config(materialized='table')}}

WITH stops AS (
    SELECT
        *
    FROM {{ ref('fct_daily_scheduled_stops') }}
),

dim_stops AS (
    SELECT *
    FROM {{ ref('dim_stops') }}
),


feeds AS (
    SELECT DISTINCT
        feed_key,
        gtfs_dataset_key,
        gtfs_dataset_name,
    FROM {{ ref('fct_daily_schedule_feeds') }}
),

monthly_stops AS (
    SELECT
        gtfs_dataset_key,
        gtfs_dataset_name,
        EXTRACT(month FROM service_date) AS month,
        EXTRACT(year FROM service_date) AS year,
        CASE
            WHEN EXTRACT(DAYOFWEEK FROM service_date) = 1 THEN "Sunday"
            WHEN EXTRACT(DAYOFWEEK FROM service_date) = 7 THEN "Saturday"
            ELSE "Weekday"
        END AS day_type,
        stop_id,
        stop_key,

        SUM(stop_event_count) AS ttl_stop_event_count,
        COUNT(DISTINCT service_date) as n_days,

    FROM stops
    INNER JOIN feeds
        ON feeds.feed_key = stops.feed_key
    GROUP BY 1, 2, 3, 4, 5, 6, 7
    -- if we group by stop_name, there will be multiple stop_ids, even within the same month for some operators
),

fct_monthly_stops AS (
    SELECT
        monthly_stops.*,
        dim_stops.tts_stop_name,
        dim_stops.pt_geom,
        dim_stops.parent_station,
        dim_stops.stop_code,
        dim_stops.stop_name,
        dim_stops.stop_desc,
        dim_stops.location_type,
        dim_stops.wheelchair_boarding,

    FROM monthly_stops
    INNER JOIN dim_stops
        ON dim_stops.key = monthly_stops.stop_key
)

SELECT * FROM fct_monthly_stops
