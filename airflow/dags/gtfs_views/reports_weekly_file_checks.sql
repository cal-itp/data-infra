---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.reports_weekly_file_checks"

tests:
  check_null:
    - feed_key
    - file_key
    - date
  check_composite_unique:
    - feed_key
    - date
    - file_key

dependencies:
  - gtfs_schedule_fact_daily_feed_files
---

SELECT
    feed_key
    -- , 'week' AS period
    , date
    , file_key
FROM  views.gtfs_schedule_fact_daily_feed_files
-- This filter works because gtfs_schedule_fact_daily_feed_files is interpolated
--  (it includes all dates, even if new data was not ingested on a given day).
WHERE date = DATE_TRUNC(date, week)
