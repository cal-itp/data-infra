---
operator: operators.SqlToWarehouseOperator
dst_table_name: "gtfs_schedule_history.calitp_feed_updates"
dependencies:
  - calitp_files_updates_load

---

SELECT DISTINCT
    calitp_itp_id
    , calitp_url_number
    , calitp_extracted_at
FROM `gtfs_schedule_history.calitp_files_updates`
WHERE is_agency_changed
