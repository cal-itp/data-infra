---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.schedule_fact_route_id_changes"

dependencies:
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
    SELECT calitp_itp_id, calitp_url_number, metric_date, route_id
    FROM `gtfs_schedule_type2.routes_clean`
    JOIN date_range ON calitp_extracted_at <= date_start
    AND calitp_deleted_at > date_start
),
table_end AS (
    SELECT calitp_itp_id, calitp_url_number, metric_date, route_id
    FROM `gtfs_schedule_type2.routes_clean`
    JOIN date_range ON calitp_extracted_at <= date_end
    AND calitp_deleted_at > date_end
),

table_partial AS (
    SELECT
  * EXCEPT (route_id)
  , t1.route_id AS start_table_route_id
  , t2.route_id AS stop_table_route_id
  , CASE
      WHEN t2.route_id IS NULL AND t1.route_id IS NOT NULL THEN 'Removed'
      WHEN t1.route_id IS NULL AND t2.route_id IS NOT NULL THEN 'Added'
      ELSE 'Unchanged'
      END AS route_id_changed
FROM table_start t1
FULL JOIN table_end t2 USING (
  calitp_itp_id,
  calitp_url_number,
  metric_date,
  route_id
))

SELECT calitp_itp_id, calitp_url_number, metric_date, route_id_changed, COUNT(*) AS n FROM table_partial GROUP BY 1, 2, 3, 4
