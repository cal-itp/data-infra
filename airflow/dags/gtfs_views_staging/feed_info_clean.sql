---
operator: operators.SqlToWarehouseOperator
dst_table_name: "gtfs_schedule_type2.feed_info_clean"
dependencies:
  - type2_loaded
---

SELECT
    * EXCEPT(feed_start_date, feed_end_date, calitp_deleted_at),
    PARSE_DATE("%Y%m%d",feed_start_date) AS feed_start_date,
    PARSE_DATE("%Y%m%d",feed_end_date) AS feed_end_date,
    FARM_FINGERPRINT(CONCAT(CAST(calitp_hash AS STRING), "___", CAST(calitp_extracted_at AS STRING)))
        AS feed_info_key,
    COALESCE(calitp_deleted_at, "2099-01-01") AS calitp_deleted_at
FROM `gtfs_schedule_type2.feed_info`
