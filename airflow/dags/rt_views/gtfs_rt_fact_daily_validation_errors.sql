---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.gtfs_rt_fact_daily_validation_errors"

description: |
  A daily roll-up of validation errors per calitp_id/url/entity/error.


fields:
  calitp_itp_id: Feed ITP ID
  calitp_url_number: Feed URL number
  rt_feed_type: GTFS realtime type (service_alerts, trip_updates, or vehicle_positions)
  error_id: The GTFS Realtime validation error ID.
  date: Date for which this feed was present in our extraction list.
  occurrences: The number of occurrences for this combination.

tests:
    check_null:
        - calitp_itp_id
        - calitp_url_number
        - rt_feed_type
        - error_id
        - date
        - occurrences
    check_composite_unique:
        - calitp_itp_id
        - calitp_url_number
        - rt_feed_type
        - error_id
        - date

external_dependencies:
  - rt_loader: all
  - gtfs_views: gtfs_schedule_dim_feeds
---

-- note that for realtime we do not (yet) have a feed_key-type identifier
-- so use calitp_itp_id plus calitp_url_number as identifier

with unioned as (
    select *
    from `gtfs_rt.validation_service_alerts`
    union all
    select *
    from `gtfs_rt.validation_trip_updates`
    union all
    select *
    from `gtfs_rt.validation_vehicle_positions`
)
error_counts as (
  SELECT
      calitp_itp_id
    , calitp_url_number
    , rt_feed_type
    , error_id
    , DATE(calitp_extracted_at) as date
    , sum(n_occurrences) as occurrences
FROM unioned
GROUP BY calitp_itp_id, calitp_url_number, rt_feed_type, error_id, date
)
SELECT t1.*,
    t2.feed_key
FROM error_counts t1
LEFT JOIN `views.gtfs_schedule_dim_feeds` t2
    ON t1.date >= t2.calitp_extracted_at and t1.date < t2.calitp_deleted_at and t1.calitp_itp_id = t2.calitp_itp_id and t1.calitp_url_number = t2.calitp_url_number
