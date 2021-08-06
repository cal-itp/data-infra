---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.gtfs_schedule_type2_feed_info"
dependencies:
  - warehouse_loaded
---

SELECT
* EXCEPT(feed_start_date, feed_end_date),
    PARSE_DATE("%Y%m%d",feed_start_date) AS feed_start_date,
    PARSE_DATE("%Y%m%d",feed_end_date) AS feed_end_date,
FARM_FINGERPRINT(CONCAT(CAST(calitp_hash AS STRING), "___", CAST(calitp_extracted_at AS STRING))) AS feed_info_key
FROM `cal-itp-data-infra-staging.gtfs_schedule_type2.feed_info`
