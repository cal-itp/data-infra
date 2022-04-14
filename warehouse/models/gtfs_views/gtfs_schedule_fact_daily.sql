{{ config(materialized='table') }}

WITH gtfs_schedule_fact_daily_feeds AS (
    SELECT *
    FROM {{ ref('gtfs_schedule_fact_daily_feeds') }}
),
gtfs_schedule_dim_feeds AS (
    SELECT *
    FROM {{ ref('gtfs_schedule_dim_feeds') }}
),
gtfs_schedule_fact_daily_feed_files AS (
    SELECT *
    FROM {{ ref('gtfs_schedule_fact_daily_feed_files') }}
),
gtfs_schedule_dim_files AS (
    SELECT *
    FROM {{ ref('gtfs_schedule_dim_files') }}
),
daily_feeds_enriched AS (

    SELECT
        *
    FROM gtfs_schedule_fact_daily_feeds
    JOIN gtfs_schedule_dim_feeds
        USING (feed_key)

),

feed_total_counts AS (
    SELECT
        date
        , COUNT(*) AS n_feeds
        , COUNT(DISTINCT calitp_itp_id) AS n_distinct_itp_ids
    FROM daily_feeds_enriched
    GROUP BY 1
),

feed_status_counts AS (
    SELECT *
    FROM
        (SELECT date, extraction_status FROM gtfs_schedule_fact_daily_feeds)
            PIVOT(COUNT(*) AS n_extract FOR extraction_status IN ("success", "error"))
),

daily_feed_files_enriched AS (
    SELECT
        date,
        table_name
    FROM gtfs_schedule_fact_daily_feed_files
    JOIN gtfs_schedule_dim_files USING (file_key)
),

file_total_counts AS (
    SELECT
        *
    FROM
        daily_feed_files_enriched
            PIVOT(
                COUNT(*) AS n_file
                FOR table_name
                IN ("shapes", "levels", "pathways", "fare_leg_rules",
                    "fare_rules", "feed_info")
            )
),

gtfs_schedule_fact_daily AS (
    SELECT
        *
    FROM feed_total_counts
    LEFT JOIN feed_status_counts USING(date)
    LEFT JOIN file_total_counts USING(date)
)

SELECT * FROM gtfs_schedule_fact_daily
