---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.gtfs_schedule_dim_stop_times"
dependencies:
  - dummy_gtfs_schedule_dims
---

SELECT
    * EXCEPT(continuous_pickup, continuous_drop_off)
    , continuous_pickup AS stop_time_continuous_pickup
    , continuous_drop_off AS stop_time_continuous_drop_off
FROM `gtfs_schedule_type2.stop_times_clean` T
