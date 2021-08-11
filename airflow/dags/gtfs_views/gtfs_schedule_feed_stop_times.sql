---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.gtfs_schedule_feed_route_trip_stops"
dependencies:
  - gtfs_schedule_feed_route_trips
  - gtfs_schedule_feed_stops
---

WITH

-- this table is stop_times, but conforming to what would be a join between
-- views.gtfs_schedule_feed_route_trips and views.gtfs_schedule_feed_stops

trips_joined AS (
    -- type2 join for trips and stop_times tables
    -- see https://sqlsunday.com/2014/11/30/joining-two-scd2-tables/
    SELECT
      T.trip_key,
      ST.* EXCEPT (calitp_extracted_at, calitp_deleted_at, calitp_hash, continuous_pickup, continuous_drop_off)
      , continuous_pickup AS stop_time_continuous_pickup
      , continuous_drop_off AS stop_time_continuous_drop_off
      , GREATEST(ST.calitp_extracted_at, T.calitp_extracted_at) AS calitp_extracted_at
      , LEAST(ST.calitp_deleted_at, T.calitp_deleted_at) AS calitp_deleted_at
    FROM `gtfs_schedule_type2.stop_times` ST
    JOIN `views.gtfs_schedule_feed_route_trips` T
        USING (calitp_itp_id, calitp_url_number, trip_id)
    WHERE
        ST.calitp_extracted_at < COALESCE(T.calitp_deleted_at, "2099-01-01")
        AND T.calitp_extracted_at < COALESCE(ST.calitp_deleted_at, "2099-01-01")
),
stops_joined AS (
  -- type2 join on above table and stops
  SELECT
    TST.trip_key
    , S.stop_key
    , TST.* EXCEPT(trip_key, calitp_extracted_at, calitp_deleted_at)
    , GREATEST(S.calitp_extracted_at, TST.calitp_extracted_at) AS calitp_extracted_at
    , LEAST(S.calitp_deleted_at, TST.calitp_deleted_at) AS calitp_deleted_at
  FROM trips_joined TST
  JOIN `views.gtfs_schedule_feed_stops` S
  USING (calitp_itp_id, calitp_url_number, stop_id)
  WHERE
      S.calitp_extracted_at < COALESCE(TST.calitp_deleted_at, "2099-01-01")
      AND TST.calitp_extracted_at < COALESCE(S.calitp_deleted_at, "2099-01-01")
)

SELECT * FROM stops_joined
