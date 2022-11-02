{{ config(materialized='table') }}

WITH fct_daily_schedule_feeds AS (
    SELECT * FROM {{ ref('fct_daily_schedule_feeds') }}
),

checks_implemented AS (
    SELECT * FROM {{ ref('stg_gtfs_guidelines__checks_implemented') }}
),

-- create an index: all feed/date/check combinations
-- we never want results from the current date, as data will be incomplete
stg_gtfs_guidelines__feed_check_index AS (
    SELECT
        daily_feeds.feed_key,
        daily_feeds.date,
        checks.check,
        checks.feature
    FROM fct_daily_schedule_feeds AS daily_feeds
    CROSS JOIN checks_implemented AS checks
    WHERE daily_feeds.date < CURRENT_DATE
)

SELECT * FROM stg_gtfs_guidelines__feed_check_index
