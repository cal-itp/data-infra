{{ config(materialized='table') }}

WITH fct_daily_all_feeds AS (
    SELECT * FROM {{ ref('fct_daily_all_feeds') }}
),

checks_intended AS (
    SELECT * FROM {{ ref('stg_gtfs_guidelines__intended_checks_v2') }}
),

-- create an index: all feed/date/check combinations
-- we never want results from the current date, as data will be incomplete
int_gtfs_guidelines_v2__feed_guideline_index AS (
    SELECT
        daily_feeds.feed_key,
        daily_feeds.date,
        checks.check,
        checks.feature
    FROM fct_daily_all_feeds AS daily_feeds
    CROSS JOIN checks_intended AS checks
    WHERE daily_feeds.date < CURRENT_DATE
)

SELECT * FROM int_gtfs_guidelines_v2__feed_guideline_index
