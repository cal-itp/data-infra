---
operator: operators.SqlToWarehouseOperator
dst_table_name: "gtfs_schedule_type2.agency_clean"
dependencies:
  - type2_loaded
---

SELECT
    * EXCEPT(calitp_deleted_at)
    , COALESCE(calitp_deleted_at, "2099-01-01") AS calitp_deleted_at
FROM `gtfs_schedule_type2.agency`
