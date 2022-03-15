---
operator: operators.SqlToWarehouseOperator
dst_table_name: "gtfs_views_staging.stop_times_clean"
dependencies:
  - type2_loaded

tests:
  check_null:
    - calitp_hash
    - stop_time_key
  check_unique:
    - stop_time_key
---

SELECT
    calitp_itp_id
    , calitp_url_number
    , TRIM(trip_id) as trip_id
    , TRIM(stop_id) as stop_id
    , TRIM(stop_sequence) as stop_sequence
    , TRIM(arrival_time) as arrival_time
    , TRIM(departure_time) as departure_time
    , TRIM(stop_headsign) as stop_headsign
    , TRIM(pickup_type) as pickup_type
    , TRIM(drop_off_type) as drop_off_type
    , TRIM(continuous_pickup) as continuous_pickup
    , TRIM(continuous_drop_off) as continuous_drop_off
    , TRIM(shape_dist_traveled) as shape_dist_traveled
    , TRIM(timepoint) as timepoint
    , calitp_extracted_at
    , calitp_hash
    , FARM_FINGERPRINT(CONCAT(CAST(calitp_hash AS STRING), "___", CAST(calitp_extracted_at AS STRING)))
        AS stop_time_key
    , COALESCE(calitp_deleted_at, "2099-01-01") AS calitp_deleted_at
FROM `gtfs_schedule_type2.stop_times`
