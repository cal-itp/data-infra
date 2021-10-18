---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.gtfs_schedule_dim_trips"

tests:
  check_null:
    - trip_key
  check_unique:
    - trip_key

dependencies:
  - dummy_gtfs_schedule_dims
---

WITH trip_dupes AS (

    -- some feeds accidentally duplicate trip records, so we have to remove them
    -- see issue https://github.com/cal-itp/data-infra/issues/287
    SELECT
        *
        , ROW_NUMBER() OVER (PARTITION BY trip_key) calitp_dupe_number
    FROM `gtfs_schedule_type2.trips_clean` T

)

SELECT * EXCEPT(calitp_dupe_number)
FROM trip_dupes
WHERE calitp_dupe_number = 1
