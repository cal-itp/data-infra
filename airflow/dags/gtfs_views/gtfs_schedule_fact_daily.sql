---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.gtfs_schedule_fact_daily"
dependencies:
  - gtfs_schedule_dim_feeds
---

WITH feed_metrics AS (
    SELECT
        full_date AS date
        , COUNT(*) AS n_feeds
        , COUNT(DISTINCT calitp_itp_id) AS n_distinct_itp_ids
    FROM `views.gtfs_schedule_dim_feeds` F
    JOIN `views.dim_date` D
        ON F.calitp_extracted_at <= D.full_date
            AND F.calitp_deleted_at > D.full_date
    GROUP BY 1
)

SELECT * FROM feed_metrics
