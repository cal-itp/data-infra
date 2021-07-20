---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.schedule_stop_id_changes"

dependencies:
  - warehouse_loaded
  - dim_date
---

WITH
date_range AS (
    SELECT
      full_date AS metric_date,
      DATE_SUB(full_date, INTERVAL 1 DAY) AS date_start,
      full_date AS date_end,
    FROM `views.dim_date`
    WHERE full_date BETWEEN '2020-01-01' AND CURRENT_DATE()
),
table_start AS (
    SELECT calitp_itp_id, calitp_url_number, metric_date, stop_id from `gtfs_schedule_type2.stops`
    JOIN date_range ON calitp_extracted_at <= date_start
    AND COALESCE(calitp_deleted_at, DATE ("2099-01-01")) > date_start
),
  table_end AS (
    SELECT calitp_itp_id, calitp_url_number, metric_date, stop_id from `gtfs_schedule_type2.stops`
    JOIN date_range ON calitp_extracted_at <= date_end
    AND COALESCE(calitp_deleted_at, DATE ("2099-01-01")) > date_end
),

table_partial AS (
    SELECT
  * EXCEPT (stop_id)
  , t1.stop_id AS start_table_stop_id
  , t2.stop_id AS stop_table_stop_id
  , CASE
      WHEN t2.stop_id IS NULL AND t1.stop_id IS NOT NULL THEN 'Removed'
      WHEN t1.stop_id IS NULL AND t2.stop_id IS NOT NULL THEN 'Added'
      ELSE 'Unchanged'
      END AS stop_id_changed
FROM table_start t1
FULL JOIN table_end t2 USING (
  calitp_itp_id,
  calitp_url_number,
  metric_date,
  stop_id
))

SELECT calitp_itp_id, calitp_url_number, metric_date, stop_id_changed, COUNT(*) AS n FROM table_partial GROUP BY 1, 2, 3, 4
