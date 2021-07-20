---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.gtfs_status_latest"
dependencies:
  - warehouse_loaded
---

WITH tbl_max AS (
  SELECT *, MAX(calitp_extracted_at) OVER () AS max_date
  FROM `gtfs_schedule_history.calitp_status`
)
SELECT * EXCEPT(max_date) FROM tbl_max
WHERE calitp_extracted_at=max_date
