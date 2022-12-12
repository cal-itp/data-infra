{{ config(materialized='table') }}

WITH date_spine AS (
    SELECT *,
        EXTRACT(DAYOFWEEK FROM date_day) AS day_num
    FROM {{ ref('util_gtfs_schedule_v2_date_spine') }}
),

dim_calendar_dates AS (
    SELECT *
    FROM {{ ref('dim_calendar_dates') }}
),

int_gtfs_schedule__long_calendar AS (
    SELECT *
    FROM {{ ref('int_gtfs_schedule__long_calendar') }}
),

boolean_calendar_dates AS (
    SELECT
        date,
        feed_key,
        key AS calendar_dates_key,
        service_id,
        CASE
            WHEN exception_type = 1 THEN TRUE
            WHEN exception_type = 2 THEN FALSE
        END AS has_service
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
        calendar_dates_key,
        service_id,
        LOGICAL_AND(has_service) AS has_service
    FROM boolean_calendar_dates
    GROUP BY date, feed_key, calendar_dates_key, service_id
),

daily_services AS (

    SELECT
        date_spine.date_day AS service_date,
        COALESCE(long_cal.feed_key, cal_dates.feed_key) AS feed_key,
        calendar_key,
        calendar_dates_key,
        long_cal.service_id AS calendar_service_id,
        long_cal.has_service AS calendar_has_service,
        cal_dates.service_id AS calendar_dates_service_id,
        cal_dates.has_service AS calendar_dates_has_service,
        COALESCE(long_cal.service_id, cal_dates.service_id) AS service_id,
        -- calendar_dates takes precedence if present: it can modify calendar
        -- if no calendar_dates, use calendar
        -- if neither, no service
        COALESCE(cal_dates.has_service, long_cal.has_service, FALSE) AS has_service
    FROM date_spine
    LEFT JOIN int_gtfs_schedule__long_calendar AS long_cal
        ON date_spine.day_num = long_cal.day_num
            AND date_spine.date_day BETWEEN long_cal.start_date AND long_cal.end_date
    LEFT JOIN summarize_calendar_dates AS cal_dates
        ON date_spine.date_day = cal_dates.date
            AND (long_cal.feed_key = cal_dates.feed_key OR long_cal.feed_key IS NULL)
            AND (long_cal.service_id = cal_dates.service_id OR long_cal.service_id IS NULL)
),

int_gtfs_schedule__all_scheduled_service AS (
    SELECT
        service_date,
        feed_key,
        calendar_key,
        calendar_dates_key,
        service_id
    FROM daily_services
    WHERE service_id IS NOT NULL
        AND has_service
)

SELECT * FROM int_gtfs_schedule__all_scheduled_service
