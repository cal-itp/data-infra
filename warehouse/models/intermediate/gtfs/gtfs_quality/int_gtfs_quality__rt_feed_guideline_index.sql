{{ config(materialized='ephemeral') }}

WITH fct_daily_rt_feed_files AS (
    SELECT * FROM {{ ref('fct_daily_rt_feed_files') }}
),

-- we never want results from the current date, as data will be incomplete
int_gtfs_quality__rt_feed_guideline_index AS (
    SELECT
        date,
        base64_url,
        feed_type,
    FROM fct_daily_rt_feed_files
    WHERE date < CURRENT_DATE
      AND base64_url IS NOT null
      AND feed_type IS NOT null
)

SELECT * FROM int_gtfs_quality__rt_feed_guideline_index
