{{ config(materialized='ephemeral') }}

WITH int_gtfs_quality__rt_feed_guideline_index AS (
    SELECT * FROM {{ ref('int_gtfs_quality__rt_feed_guideline_index') }}
    -- 1/13/23 is when the aggregator scraper started running
    WHERE date >= '2023-01-13'
),

distinct_aggregators AS (
    SELECT DISTINCT aggregator
      FROM {{ ref('stg_gtfs_quality__scraped_urls') }}
),

int_gtfs_quality__rt_feed_guideline_index_aggregator AS (
    SELECT *
      FROM int_gtfs_quality__rt_feed_guideline_index
     CROSS JOIN distinct_aggregators
)

SELECT * FROM int_gtfs_quality__rt_feed_guideline_index_aggregator
