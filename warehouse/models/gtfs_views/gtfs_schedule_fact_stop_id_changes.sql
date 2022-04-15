{{ config(materialized='table') }}

WITH dim_metric_date AS (
    SELECT *
    FROM {{ ref('dim_metric_date') }}
),
gtfs_schedule_dim_feeds AS (
    SELECT *
    FROM {{ ref('gtfs_schedule_dim_feeds') }}
),
gtfs_schedule_dim_stops AS (
    SELECT *
    FROM {{ ref('gtfs_schedule_dim_stops') }}
),
date_range AS (
    SELECT
      metric_period
      , metric_date
      , start_date
      , end_date
    FROM dim_metric_date
    WHERE
        is_gtfs_schedule_range
        AND metric_type != "daily"
),

source_table AS (

    SELECT *,
    stop_id as source_id
    FROM gtfs_schedule_dim_stops

),

table_start AS (
    SELECT
      calitp_itp_id,
      calitp_url_number,
      metric_period,
      metric_date, source_id
    FROM source_table
    JOIN date_range ON calitp_extracted_at <= start_date
    AND calitp_deleted_at > start_date
),

table_end AS (
    SELECT
      calitp_itp_id,
      calitp_url_number,
      metric_period,
      metric_date,
      source_id
    FROM source_table
    JOIN date_range ON calitp_extracted_at <= end_date
    AND calitp_deleted_at > end_date
),

table_partial AS (

    SELECT
      * EXCEPT (source_id)
      , t1.source_id AS start_table_source_id
      , t2.source_id AS stop_table_source_id
      , CASE
          WHEN t2.source_id IS NULL AND t1.source_id IS NOT NULL THEN 'Removed'
          WHEN t1.source_id IS NULL AND t2.source_id IS NOT NULL THEN 'Added'
          ELSE 'Unchanged'
          END AS change_status
    FROM table_start t1
    FULL JOIN table_end t2
      USING ( calitp_itp_id, calitp_url_number, metric_period, metric_date, source_id)

),

metric_counts AS (

    SELECT
        calitp_itp_id
        , calitp_url_number
        , metric_period
        , metric_date
        , change_status
        , COUNT(*) AS n
    FROM table_partial GROUP BY 1, 2, 3, 4, 5

),
gtfs_schedule_fact_stop_id_changes AS (
  SELECT
      T2.feed_key
      , T1.*
  FROM metric_counts T1
  JOIN gtfs_schedule_dim_feeds T2
      USING(calitp_itp_id, calitp_url_number)
  WHERE
      T2.calitp_extracted_at <= T1.metric_date
      AND T2.calitp_deleted_at > T1.metric_date
)


 SELECT * FROM gtfs_schedule_fact_stop_id_changes
