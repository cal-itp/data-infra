---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.gtfs_schedule_fact_daily_trips"

tests:
  check_null:
    - trip_key
    - service_date
    - service_id
  check_composite_unique:
    - trip_key
    - service_date
    - service_id

dependencies:
  - gtfs_schedule_stg_daily_service
  - gtfs_schedule_stg_stop_times
---

# Each trip with scheduled service on a date, augmented with route_id, first departure,
# and last arrival timestamps.
#
WITH

stg_daily_service_keyed AS (

  SELECT
    T2.feed_key
    , T1.*
  FROM `views.gtfs_schedule_stg_daily_service` T1
  JOIN `views.gtfs_schedule_dim_feeds` T2
    ON
      T1.calitp_itp_id = T2.calitp_itp_id
      AND T1.calitp_url_number = T2.calitp_url_number
      AND T2.calitp_extracted_at <= T1.service_date
      AND T2.calitp_deleted_at > T1.service_date

),

daily_service_trips AS (
  # Daily service for each trip. Note that scheduled service in the calendar
  # can have multiple trips associated with it, via the service_id key.
  # (i.e. calendar service to trips is 1-to-many)
  SELECT
    t1.feed_key
    , t2.trip_key
    , t2.trip_id
    , t2.route_id
    , t1.* EXCEPT (feed_key)
  FROM stg_daily_service_keyed t1
  JOIN `views.gtfs_schedule_dim_trips` t2
    USING (calitp_itp_id, calitp_url_number, service_id)
  WHERE
    t2.calitp_extracted_at <= t1.service_date
    AND t2.calitp_deleted_at > t1.service_date
),
service_dates AS (
  # Each unique value for service_date
  (SELECT DISTINCT service_date FROM `views.gtfs_schedule_stg_daily_service`)
),
trip_summary AS (
  # Trip metrics for each possible service date (e.g. for a given trip that existed
  # on this day, when was its last arrival? how many stops did it have?)
  SELECT
    t1.calitp_itp_id
    , t1.calitp_url_number
    , t1.trip_id
    , t2.service_date
    , COUNT(DISTINCT t1.stop_id) AS n_stops
    , COUNT(*) AS n_stop_times
    , MIN(t1.departure_ts) AS trip_first_departure_ts
    , MAX(t1.arrival_ts) AS trip_last_arrival_ts
  FROM `views.gtfs_schedule_dim_stop_times` t1
  JOIN  service_dates t2
  ON t1.calitp_extracted_at <= t2.service_date
    AND COALESCE(t1.calitp_deleted_at, DATE("2099-01-01")) > t2.service_date
  GROUP BY 1, 2, 3, 4
)

SELECT
  t1.*
  , t2.* EXCEPT(calitp_itp_id, calitp_url_number, trip_id, service_date)
  , (t2.trip_last_arrival_ts - t2.trip_first_departure_ts) / 3600 AS service_hours
FROM daily_service_trips t1
JOIN trip_summary t2
  USING(calitp_itp_id, calitp_url_number, trip_id, service_date)
