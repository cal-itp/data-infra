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
        daily_feeds.date AS service_date,
        cal_dates.date AS cd_date,
        daily_feeds.feed_key,
        long_cal.service_id AS calendar_service_id,
        long_cal.service_indicator AS calendar_service_indicator,
        cal_dates.service_id AS calendar_dates_service_id,
        cal_dates.service_indicator AS calendar_dates_service_indicator,
        COALESCE(long_cal.service_id, cal_dates.service_id) AS service_id,
        -- calendar_dates takes precedence if present: it can modify calendar
        -- if no calendar_dates, use calendar
        -- if neither, no service
        COALESCE(cal_dates.service_indicator, long_cal.service_indicator, FALSE) AS service_indicator
    FROM fct_daily_schedule_feeds AS daily_feeds
    LEFT JOIN int_gtfs_schedule__long_calendar AS long_cal
        ON daily_feeds.feed_key = long_cal.feed_key
            AND daily_feeds.day_num = long_cal.day_num
            AND daily_feeds.date BETWEEN long_cal.start_date AND long_cal.end_date
    LEFT JOIN summarize_calendar_dates AS cal_dates
        ON daily_feeds.feed_key = cal_dates.feed_key
            AND daily_feeds.date = cal_dates.date
            AND (long_cal.service_id = cal_dates.service_id OR long_cal.service_id IS NULL)
),

int_gtfs_schedule__daily_scheduled_service_index AS (
    SELECT
        service_date,
        cd_date,
        feed_key,
        service_id
    FROM daily_services
    WHERE service_id IS NOT NULL
        AND service_indicator
)

SELECT * FROM int_gtfs_schedule__daily_scheduled_service_index
