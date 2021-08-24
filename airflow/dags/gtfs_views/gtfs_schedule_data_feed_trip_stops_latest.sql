---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.gtfs_schedule_data_feed_trip_stops"
dependencies:
  - gtfs_schedule_index_feed_trip_stops
---

SELECT
    Feed.calitp_itp_id
    , Feed.calitp_url_number
    , Route.route_id
    , Trip.trip_id
    , Stop.stop_id
    , * EXCEPT(calitp_itp_id, calitp_url_number, calitp_hash, calitp_extracted_at, calitp_deleted_at, route_id, trip_id, stop_id)
    , Indx.calitp_extracted_at
    , Indx.calitp_deleted_at
FROM `views.gtfs_schedule_index_feed_trip_stops` Indx
LEFT JOIN `views.gtfs_schedule_dim_feeds` Feed USING (feed_key)
LEFT JOIN `views.gtfs_schedule_dim_routes` Route USING (route_key)
LEFT JOIN `views.gtfs_schedule_dim_trips` Trip USING (trip_key)
LEFT JOIN `views.gtfs_schedule_dim_stop_times` USING (stop_time_key)
LEFT JOIN `views.gtfs_schedule_dim_stops` Stop USING (stop_key)
