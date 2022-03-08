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
  - rt_loader: external_validation_service_alerts
---

-- note that for realtime we do not (yet) have a feed_key-type identifier
-- so use calitp_itp_id plus calitp_url_number as identifier

with unioned as (
    -- TODO: re-enable this when we've had a service alert validation error message, if ever
    -- Without any files, bigquery just has a single default "index" column and you can't
    -- specify a schema for parquet format external tables
--     select *
--     from `cal-itp-data-infra.gtfs_rt.validation_service_alerts`
--     union all
    select *
    from `cal-itp-data-infra.gtfs_rt.validation_trip_updates`
    union all
    select *
    from `cal-itp-data-infra.gtfs_rt.validation_vehicle_positions`
)
SELECT
      calitp_itp_id
    , calitp_url_number
    , rt_feed_type
    , error_id
    , DATE(calitp_extracted_at) as date
    , sum(n_occurrences) as occurrences

FROM unioned
GROUP BY calitp_itp_id, calitp_url_number, rt_feed_type, error_id, date
