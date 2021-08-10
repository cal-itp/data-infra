---
operator: operators.SqlToWarehouseOperator
dst_table_name: "gtfs_schedule_type2.routes_clean"
dependencies:
  - warehouse_loaded
---



SELECT *,
FARM_FINGERPRINT(CONCAT(CAST(calitp_hash AS STRING), "___", CAST(calitp_extracted_at AS STRING))) AS route_key
FROM `cal-itp-data-infra-staging.gtfs_schedule_type2.routes`
