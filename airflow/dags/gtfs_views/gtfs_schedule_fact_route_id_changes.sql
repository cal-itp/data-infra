---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.gtfs_schedule_fact_route_id_changes"

tests:
  check_null:
    - feed_key
    - period
    - period_date
    - change_status

  check_composite_unique:
    - feed_key
    - period
    - period_date
    - change_status


dependencies:
  - dim_metric_date
---

WITH

date_range AS (
    SELECT
      period
      , period_date
      , start_date
      , end_date
    FROM `views.dim_metric_date`
    WHERE
        is_gtfs_schedule_range
        AND period_type != "daily"
),

source_table AS (

    SELECT *, route_id AS source_id FROM `views.gtfs_schedule_dim_routes`

),

table_start AS (
    SELECT calitp_itp_id, calitp_url_number, period, period_date, source_id
    FROM source_table
    JOIN date_range ON calitp_extracted_at <= start_date
    AND calitp_deleted_at > start_date
),

table_end AS (
    SELECT calitp_itp_id, calitp_url_number, period, period_date, source_id
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
      USING ( calitp_itp_id, calitp_url_number, period, period_date, source_id)

),

metric_counts AS (

    SELECT
        calitp_itp_id
        , calitp_url_number
        , period
        , period_date
        , change_status
        , COUNT(*) AS n
    FROM table_partial GROUP BY 1, 2, 3, 4, 5

)

SELECT
    T2.feed_key
    , T1.*
FROM metric_counts T1
JOIN `views.gtfs_schedule_dim_feeds` T2
    USING(calitp_itp_id, calitp_url_number)
WHERE
    T2.calitp_extracted_at <= T1.period_date
    AND T2.calitp_deleted_at > T1.period_date
