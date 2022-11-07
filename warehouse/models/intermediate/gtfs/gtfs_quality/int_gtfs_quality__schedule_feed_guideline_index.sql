{{ config(materialized='ephemeral') }}

WITH fct_daily_schedule_feeds AS (
    SELECT * FROM {{ ref('fct_daily_schedule_feeds') }}
),

-- we never want results from the current date, as data will be incomplete
int_gtfs_quality__schedule_feed_guideline_index AS (
    SELECT
        feed_key,
        date,
    FROM fct_daily_schedule_feeds
    WHERE date < CURRENT_DATE
)

SELECT * FROM int_gtfs_quality__schedule_feed_guideline_index
