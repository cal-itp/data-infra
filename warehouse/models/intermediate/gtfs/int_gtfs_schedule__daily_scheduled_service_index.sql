{{ config(materialized='table') }}

WITH fct_daily_schedule_feeds AS (
    SELECT
        *,
        EXTRACT(DAYOFWEEK FROM date) AS day_num
    FROM {{ ref('fct_daily_schedule_feeds') }}
),

all_scheduled_service AS (
    SELECT *
    FROM {{ ref('int_gtfs_schedule__all_scheduled_service') }}
),

int_gtfs_schedule__daily_scheduled_service_index AS (
    SELECT
        service_date,
        fct_daily_schedule_feeds.feed_key,
        service_id,
        calendar_key,
        calendar_dates_key
    FROM all_scheduled_service
    INNER JOIN fct_daily_schedule_feeds
        ON all_scheduled_service.feed_key = fct_daily_schedule_feeds.feed_key
        AND all_scheduled_service.service_date = fct_daily_schedule_feeds.date
)

SELECT * FROM int_gtfs_schedule__daily_scheduled_service_index
