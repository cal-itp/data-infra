---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.gtfs_schedule_index_feed_trips"
dependencies:
  - gtfs_schedule_index_feed_routes
  - gtfs_schedule_dim_trips
---

SELECT
  T1.feed_key
  , T1.route_key
  , T2.trip_key
  , calitp_itp_id
  , calitp_url_number
  , route_id
  , T2.trip_id
  , GREATEST(T1.calitp_extracted_at, T2.calitp_extracted_at) AS calitp_extracted_at
  , LEAST(T1.calitp_deleted_at, T2.calitp_deleted_at) AS calitp_deleted_at
FROM `views.gtfs_schedule_index_feed_routes` T1
JOIN `views.gtfs_schedule_dim_trips` T2
USING (calitp_itp_id, calitp_url_number, route_id)
WHERE
    T1.calitp_extracted_at < T2.calitp_deleted_at
    AND T2.calitp_extracted_at < T1.calitp_deleted_at
