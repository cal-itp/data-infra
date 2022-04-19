{{ config(materialized='table') }}

WITH gtfs_schedule_fact_daily_feed_files AS (
    SELECT *
    FROM {{ ref('gtfs_schedule_fact_daily_feed_files') }}
),

reports_weekly_file_checks AS (
    SELECT
        feed_key,
        -- , 'week' AS period
        date,
        file_key
    FROM gtfs_schedule_fact_daily_feed_files
    -- This filter works because gtfs_schedule_fact_daily_feed_files is interpolated
    --  (it includes all dates, even if new data was not ingested on a given day).
    WHERE date = DATE_TRUNC(date, WEEK)
)

SELECT * FROM reports_weekly_file_checks
