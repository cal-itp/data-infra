---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.gtfs_schedule_index_feed_stops"
dependencies:
  - gtfs_schedule_index_feed_trips
  - gtfs_schedule_dim_stop_times
  - gtfs_schedule_dim_stops
---

WITH

feed_stop_times AS (
    SELECT
      T1.feed_key
      , T1.route_key
      , T1.trip_key
      , T2.stop_times_key
      , calitp_itp_id
      , calitp_url_number
      , stop_id
      , GREATEST(T1.calitp_extracted_at, T2.calitp_extracted_at) AS calitp_extracted_at
      , LEAST(T1.calitp_deleted_at, T2.calitp_deleted_at) AS calitp_deleted_at
    FROM `views.gtfs_schedule_index_feed_trips` T1
    JOIN `views.gtfs_schedule_dim_stop_times` T2
        USING (calitp_itp_id, calitp_url_number, trip_id)
    WHERE
        T1.calitp_extracted_at < T2.calitp_deleted_at
        AND T2.calitp_extracted_at < T1.calitp_deleted_at
),
feed_stops AS (
    SELECT
      T1.feed_key
      , T1.route_key
      , T1.trip_key
      , T1.stop_times_key
      , T2.stop_key
      , GREATEST(T1.calitp_extracted_at, T2.calitp_extracted_at) AS calitp_extracted_at
      , LEAST(T1.calitp_deleted_at, T2.calitp_deleted_at) AS calitp_deleted_at
    FROM feed_stop_times T1
    JOIN `views.gtfs_schedule_dim_stops` T2
       USING (calitp_itp_id, calitp_url_number, stop_id)
    WHERE
        T1.calitp_extracted_at < COALESCE(T2.calitp_deleted_at, "2099-01-01")
        AND T2.calitp_extracted_at < COALESCE(T1.calitp_deleted_at, "2099-01-01")
)

SELECT * FROM feed_stops
