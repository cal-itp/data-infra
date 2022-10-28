{{ config(materialized='table') }}

WITH dim_calendar_dates AS (
    SELECT *
    FROM {{ ref('dim_calendar_dates') }}
),

int_gtfs_schedule__long_calendar AS (
    SELECT *
    FROM {{ ref('int_gtfs_schedule__long_calendar') }}
),

fct_daily_schedule_feeds AS (
    SELECT
        *,
        EXTRACT(DAYOFWEEK FROM date) AS day_num
    FROM {{ ref('fct_daily_schedule_feeds') }}
),

boolean_calendar_dates AS (
    SELECT
        date,
        feed_key,
        service_id,
        CASE
            WHEN exception_type = 1 THEN TRUE
            WHEN exception_type = 2 THEN FALSE
        END AS service_indicator
    FROM dim_calendar_dates
),

-- decide that exception type 2 trumps exception type 1
-- i.e., if same date appears twice with two exception types
-- the cancelation wins and we say no service on that date
-- (this generally shouldn't happen)
summarize_calendar_dates AS (
    SELECT
        date,
        feed_key,
        service_id,
        LOGICAL_AND(service_indicator) AS service_indicator
    FROM boolean_calendar_dates
    GROUP BY date, feed_key, service_id
),

daily_services AS (

    SELECT
        t1.date AS service_date,
        t3.date AS cd_date,
        t1.feed_key,
        t2.service_id AS calendar_service_id,
        t2.service_indicator AS calendar_service_indicator,
        t3.service_id AS calendar_dates_service_id,
        t3.service_indicator AS calendar_dates_service_indicator,
        COALESCE(t2.service_id, t3.service_id) AS service_id,
        -- calendar_dates takes precedence if present: it can modify calendar
        -- if no calendar_dates, use calendar
        -- if neither, no service
        COALESCE(t3.service_indicator, t2.service_indicator, FALSE) AS service_indicator
    FROM fct_daily_schedule_feeds AS t1
    LEFT JOIN int_gtfs_schedule__long_calendar AS t2
        ON t1.feed_key = t2.feed_key
            AND t1.day_num = t2.day_num
            AND t1.date BETWEEN t2.start_date AND t2.end_date
    LEFT JOIN summarize_calendar_dates AS t3
        ON t1.feed_key = t3.feed_key
            AND t1.date = t3.date
            AND (t2.service_id = t3.service_id OR t2.service_id IS NULL)
),

fct_daily_scheduled_service AS (
    SELECT
        service_date,
        cd_date,
        feed_key,
        service_id
    FROM daily_services
    WHERE service_id IS NOT NULL
        AND service_indicator
)

SELECT * FROM fct_daily_scheduled_service
