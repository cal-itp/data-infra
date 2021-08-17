---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.gtfs_schedule_index_feed_routes"
dependencies:
  - gtfs_schedule_dim_feeds
  - gtfs_schedule_dim_routes
---

SELECT
  T1.feed_key
  , T2.route_key
  , calitp_itp_id
  , calitp_url_number
  , T2.route_id
  , GREATEST(T1.calitp_extracted_at, T2.calitp_extracted_at) AS calitp_extracted_at
  , LEAST(T1.calitp_deleted_at, T2.calitp_deleted_at) AS calitp_deleted_at
FROM `views.gtfs_schedule_dim_feeds` T1
JOIN `views.gtfs_schedule_dim_routes` T2
    USING (calitp_itp_id, calitp_url_number)
WHERE
    T1.calitp_extracted_at < T2.calitp_deleted_at
    AND T2.calitp_extracted_at < T1.calitp_deleted_at
