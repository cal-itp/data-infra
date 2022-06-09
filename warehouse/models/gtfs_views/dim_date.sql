{{ config(materialized='table') }}

-- from https://gist.github.com/ewhauser/d7dd635ad2d4b20331c7f18038f04817

WITH raw_dates AS (
    SELECT
        *
    FROM
        UNNEST(GENERATE_DATE_ARRAY('2021-01-01', '2031-01-01', INTERVAL 1 DAY)) AS d
),

dim_date AS (
    SELECT
        FORMAT_DATE('%F', d) AS id,
        {{ farm_surrogate_key(["FORMAT_DATE('%F', d)"]) }} AS key,
        d AS full_date,
        EXTRACT(YEAR FROM d) AS year,
        EXTRACT(WEEK FROM d) AS year_week,
        EXTRACT(DAYOFYEAR FROM d) AS year_day,
        FORMAT_DATE('%Q', d) AS qtr,
        EXTRACT(MONTH FROM d) AS month,
        FORMAT_DATE('%B', d) AS month_name,
        EXTRACT(DAY FROM d) AS month_day,
        FORMAT_DATE('%w', d) AS week_day,
        FORMAT_DATE('%A', d) AS day_name,
        (CASE WHEN FORMAT_DATE('%A', d) IN ('Sunday', 'Saturday') THEN 0 ELSE 1 END) AS day_is_weekday,
        DATETIME_TRUNC(d, DAY) = DATETIME_TRUNC(d, QUARTER) AS is_quarter_start,
        DATETIME_TRUNC(d, DAY) = DATETIME_TRUNC(d, MONTH) AS is_month_start,
        d < CURRENT_DATE() AS is_in_past,
        d <= CURRENT_DATE() AS is_in_past_or_present,
        d > CURRENT_DATE() AS is_in_future,
        (d > "2021-04-15" AND d <= CURRENT_DATE()) AS is_gtfs_schedule_range
    FROM raw_dates
)

SELECT * FROM dim_date
