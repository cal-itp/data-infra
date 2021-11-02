---
operator: operators.SqlToWarehouseOperator
dst_table_name: "gtfs_schedule_history.calitp_feed_latest"
dependencies:
  - calitp_feed_updates

---

SELECT
    calitp_itp_id
    , calitp_url_number
    , MAX(calitp_extracted_at) as calitp_extracted_at
FROM `{{ "gtfs_schedule_history.calitp_feed_updates" | table }}`
GROUP BY 1, 2
