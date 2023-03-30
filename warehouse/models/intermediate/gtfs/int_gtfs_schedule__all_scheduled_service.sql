{{ config(materialized='table') }}

WITH dim_calendar_dates AS (
    SELECT *
    FROM {{ ref('dim_calendar_dates') }}
),

int_gtfs_schedule__long_calendar AS (
    SELECT *
    FROM {{ ref('int_gtfs_schedule__long_calendar') }}
),

boolean_calendar_dates AS (
    SELECT
        -- at time of writing, this will be identical to `calendar_dates_key`, but just in case?
        {{ dbt_utils.generate_surrogate_key(['feed_key', 'service_id', 'date']) }} AS key,
        date AS service_date,
        feed_key,
        _feed_valid_from,
        key AS calendar_dates_key,
        service_id,
        CASE
            WHEN exception_type = 1 THEN TRUE
            WHEN exception_type = 2 THEN FALSE
        END AS service_bool
    FROM dim_calendar_dates
),

daily_services AS (
    SELECT
        -- these values will be identical so doesn't matter which is first in coalesce
        COALESCE(long_cal.key, cal_dates.key) AS key,
        COALESCE(long_cal.service_date, cal_dates.service_date) AS service_date,
        COALESCE(long_cal.feed_key, cal_dates.feed_key) AS feed_key,
        COALESCE(long_cal._feed_valid_from, cal_dates._feed_valid_from) AS _feed_valid_from,
        COALESCE(long_cal.service_id, cal_dates.service_id) AS service_id,
        -- calendar_dates takes precedence if present: it can modify calendar
        -- if no calendar_dates, use calendar
        -- if neither, no service
        COALESCE(cal_dates.service_bool, long_cal.service_bool) AS service_bool,
        calendar_key,
        calendar_dates_key
    FROM int_gtfs_schedule__long_calendar AS long_cal
    FULL OUTER JOIN boolean_calendar_dates AS cal_dates
        USING (key)
),

int_gtfs_schedule__all_scheduled_service AS (
    SELECT
        key,
        service_date,
        feed_key,
        _feed_valid_from,
        calendar_key,
        calendar_dates_key,
        service_id
    FROM daily_services
    WHERE service_bool
)

SELECT * FROM int_gtfs_schedule__all_scheduled_service
