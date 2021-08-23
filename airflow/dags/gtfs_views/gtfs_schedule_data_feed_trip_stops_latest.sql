---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.gtfs_schedule_data_feed_trip_stops"
dependencies:
  - gtfs_schedule_index_feed_trip_stops
---

SELECT
    F.calitp_itp_id
    , F.calitp_url_number
    , * EXCEPT(calitp_itp_id, calitp_url_number, calitp_hash, calitp_extracted_at, calitp_deleted_at)
    , Indx.calitp_extracted_at
    , Indx.calitp_deleted_at
FROM `views.gtfs_schedule_index_feed_trip_stops` Indx
LEFT JOIN `views.gtfs_schedule_dim_feeds` F USING (feed_key)
LEFT JOIN `views.gtfs_schedule_dim_trips` USING (trip_key)
LEFT JOIN `views.gtfs_schedule_dim_stop_times` USING (stop_time_key)
LEFT JOIN `views.gtfs_schedule_dim_stops` USING (stop_key)
