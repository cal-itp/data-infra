---
operator: operators.SqlToWarehouseOperator
dst_table_name: "gtfs_schedule_history.calitp_feed_latest"
dependencies:
  - calitp_feed_status

---

SELECT
    *
FROM `gtfs_schedule_history.calitp_feed_status`
WHERE is_latest_load
