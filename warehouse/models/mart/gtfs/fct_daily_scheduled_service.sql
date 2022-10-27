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
summarize_calendar_dates AS (
    SELECT
        date,
        feed_key,
        service_id,
        LOGICAL_AND(service_indicator) AS service_indicator
    FROM boolean_calendar_dates
    GROUP BY date, feed_key, service_id
),


--   * is_in_service for service_date(s) past today are not stable. They reflect
--     what the most recent feed thinks will be in service in e.g. 2050-01-01.
-- preprocess calendar dates

daily_services AS (

    SELECT
        t1.date AS service_date,
        t1.feed_key,
        t2.service_id AS calendar_service_id,
        t2.service_indicator AS calendar_service_indicator,
        t3.service_id AS calendar_dates_service_id,
        t3.service_indicator AS calendar_dates_service_indicator,
        COALESCE(t2.service_id, t3.service_id) AS service_id,
        COALESCE(t2.service_indicator, TRUE)
        AND COALESCE(t3.service_indicator, TRUE)
        AND ((t2.service_id IS NOT NULL) OR (t3.service_id IS NOT NULL)) AS service_indicator
    FROM fct_daily_schedule_feeds AS t1
    LEFT JOIN int_gtfs_schedule__long_calendar AS t2
        ON t1.feed_key = t2.feed_key
            AND t1.day_num = t2.day_num
            AND t1.date BETWEEN t2.start_date AND t2.end_date
    FULL OUTER JOIN summarize_calendar_dates AS t3
        ON t1.feed_key = t3.feed_key
            AND t1.date = t3.date
            AND t2.service_id = t3.service_id
)


SELECT * FROM daily_services
