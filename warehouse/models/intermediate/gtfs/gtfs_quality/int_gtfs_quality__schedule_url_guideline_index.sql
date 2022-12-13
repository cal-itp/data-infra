{{ config(materialized='ephemeral') }}

WITH fct_schedule_feed_downloads AS (
    SELECT *,
           EXTRACT(date FROM ts) AS date
     FROM {{ ref('fct_schedule_feed_downloads') }}
),

-- we never want results from the current date, as data will be incomplete
int_gtfs_quality__schedule_url_guideline_index AS (
    SELECT DISTINCT
        date,
        base64_url
    FROM fct_schedule_feed_downloads
    WHERE date < CURRENT_DATE
)

SELECT * FROM int_gtfs_quality__schedule_url_guideline_index
