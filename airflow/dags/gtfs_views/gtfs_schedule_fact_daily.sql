---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.gtfs_schedule_fact_daily"
dependencies:
  - gtfs_schedule_fact_daily_feeds
  - gtfs_schedule_fact_daily_feed_files
---


WITH

daily_feeds AS (

    SELECT * FROM `views.gtfs_schedule_fact_daily_feeds`

),

daily_feeds_enriched AS (

    SELECT
        *
    FROM daily_feeds
    JOIN `views.gtfs_schedule_dim_feeds`
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
        (SELECT date, extraction_status FROM daily_feeds)
            PIVOT(COUNT(*) AS n_extract FOR extraction_status IN ("success", "error"))
),

daily_feed_files_enriched AS (
    SELECT
        date,
        table_name
    FROM `views.gtfs_schedule_fact_daily_feed_files`
    JOIN `views.gtfs_schedule_dim_files` USING (file_key)
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

final AS (
    SELECT
        *
    FROM feed_total_counts
    LEFT JOIN feed_status_counts USING(date)
    LEFT JOIN file_total_counts USING(date)
)

SELECT * FROM final
