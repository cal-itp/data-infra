---
operator: operators.SqlToWarehouseOperator
dst_table_name: "gtfs_schedule_type2.calitp_feeds"
dependencies:
  - merge_updates
---

With gtfs_schedule_feed_snapshot AS
(
    SELECT itp_id, url_number, gtfs_schedule_url, fn
    FROM `gtfs_schedule_history.tmp_calitp_feeds`
)


SELECT DATE(REGEXP_SUBSTR(fn, "/schedule/([0-9]+-[0-9]+-[0-9]+)")) AS date
FROM gtfs_schedule_feed_snapshot
