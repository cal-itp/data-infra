---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.gtfs_schedule_route_trip_stops_history"
dependencies:
  - warehouse_loaded
---

WITH

-- this query contains 3 steps for doing a full historical join table
-- you can query on calitp_extracted_at IS NULL to get the latest data
--   * inner join trips to stop_times
--   * inner join to stops
--   * inner join to routes
-- note that the column names continuous_pickup/drop_off are used in both the routes and stop_times
-- tables, so the table names were prefixed to them (e.g. routes_continuous_pickup)

trip_stop_times AS (
    -- type2 join for trips and stop_times tables
    -- see https://sqlsunday.com/2014/11/30/joining-two-scd2-tables/
    SELECT
      * EXCEPT (calitp_extracted_at, calitp_deleted_at, calitp_hash)
      , GREATEST(ST.calitp_extracted_at, T.calitp_extracted_at) AS calitp_extracted_at
      , LEAST(ST.calitp_deleted_at, T.calitp_deleted_at) AS calitp_deleted_at
    FROM `cal-itp-data-infra.gtfs_schedule_type2.stop_times` ST
    JOIN `cal-itp-data-infra.gtfs_schedule_type2.trips` T
        USING (calitp_itp_id, calitp_url_number, trip_id)
    WHERE
        ST.calitp_extracted_at < COALESCE(T.calitp_deleted_at, "2099-01-01")
        AND T.calitp_extracted_at < COALESCE(ST.calitp_deleted_at, "2099-01-01")
),
trip_stops AS (
  -- type2 join on above table and stops
  SELECT
    * EXCEPT(calitp_extracted_at, calitp_deleted_at, calitp_hash, continuous_pickup, continuous_drop_off)
    , continuous_pickup AS stop_time_continuous_pickup
    , continuous_drop_off AS stop_time_continuous_drop_off
    , GREATEST(S.calitp_extracted_at, TST.calitp_extracted_at) AS calitp_extracted_at
    , LEAST(S.calitp_deleted_at, TST.calitp_deleted_at) AS calitp_deleted_at
  FROM trip_stop_times TST
  JOIN `cal-itp-data-infra.gtfs_schedule_type2.stops` S
  USING (calitp_itp_id, calitp_url_number, stop_id)
  WHERE
      S.calitp_extracted_at < COALESCE(TST.calitp_deleted_at, "2099-01-01")
      AND TST.calitp_extracted_at < COALESCE(S.calitp_deleted_at, "2099-01-01")
),
route_trip_stops AS (
  -- type2 join on above table and routes
  SELECT
    * EXCEPT(calitp_extracted_at, calitp_deleted_at, calitp_hash, continuous_pickup, continuous_drop_off)
    , continuous_pickup AS route_continuous_pickup
    , continuous_drop_off AS route_continuous_drop_off
    , GREATEST(R.calitp_extracted_at, TST.calitp_extracted_at) AS calitp_extracted_at
    , LEAST(R.calitp_deleted_at, TST.calitp_deleted_at) AS calitp_deleted_at
  FROM trip_stops TST
  JOIN `cal-itp-data-infra.gtfs_schedule_type2.routes` R
  USING (calitp_itp_id, calitp_url_number, route_id)
  WHERE
      R.calitp_extracted_at < COALESCE(TST.calitp_deleted_at, "2099-01-01")
      AND TST.calitp_extracted_at < COALESCE(R.calitp_deleted_at, "2099-01-01")
)

SELECT * FROM route_trip_stops
