---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.gtfs_schedule_route_trip_stops_latest"
dependencies:
  - gtfs_schedule_route_trip_stops_history
---

SELECT * FROM `views.gtfs_schedule_route_trip_stops_history` WHERE calitp_extracted_at IS NULL
