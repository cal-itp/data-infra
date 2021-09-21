---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.gtfs_schedule_stg_daily_service"

tests:
  check_composite_unique:
    - service_date
    - service_id
    - calitp_itp_id
    - calitp_url_number

dependencies:
  - dim_date
  - gtfs_schedule_dim_trips
  - gtfs_schedule_stg_calendar_long
---

# For a given service_date, find the latest feed describing whether that date
# is in service or not. For example, for 2021-04-10, the latest active feed
# might be from 2021-04-09 (or even earlier, if it has not been updated recently).
# Key features:
#   * There should be one entry per feed x service_date
#   * service_date may extend far into the future (depending on service_date_end).
#     In this case we only extend out to a year from current date.
#   * is_in_service for service_date(s) past today are not stable. They reflect
#     what the most recent feed thinks will be in service in e.g. 2050-01-01.
WITH
  # preprocess calendar dates
  cal_dates AS (
    SELECT
      * EXCEPT (date)
      , date AS service_date
    FROM (
        -- deduplicate calendar_dates, which does not have a unique id column
        -- and has identical entries in rare cases
        SELECT DISTINCT * FROM `gtfs_schedule_type2.calendar_dates_clean`
    )
  ),

  # for each day in our date calendar, get service entries that existed
  # in the feed on that day (for that day).
  cal_dates_daily AS (
    SELECT
      t1.*
    FROM cal_dates t1
    JOIN `views.dim_date` t2
      ON t1.calitp_extracted_at <= t2.full_date
        AND t1.calitp_deleted_at > t2.full_date
        AND t1.service_date = t2.full_date
  ),

  # inclusions from calendar_dates
  date_include AS (
    SELECT
      calitp_itp_id
      , calitp_url_number
      , service_id
      , service_date
      , TRUE AS service_inclusion
    FROM cal_dates_daily
    WHERE cal_dates_daily.exception_type = "1"
  ),

  # exclusions from calendar_dates
  date_exclude AS (
    SELECT
      calitp_itp_id
      , calitp_url_number
      , service_id
      , service_date
      , TRUE AS service_exclusion
    FROM cal_dates_daily
    WHERE cal_dates_daily.exception_type = "2"
  ),
  # for the active calendar entries on a each date (e.g. from the latest feed
  # on that date), get the service indicator (0 for out of service, 1 for in).
  calendar_daily AS (
    SELECT
      t1.* EXCEPT(start_date, end_date, day_name)
      , t1.start_date AS service_start_date
      , t1.end_date AS service_end_date
      , t2.full_date AS service_date
    FROM  `views.gtfs_schedule_stg_calendar_long` t1
    JOIN `views.dim_date` t2
      ON
        # use full_date to get active schedule on that date, and ensure
        # that entries have same day_name
        t1.calitp_extracted_at <= t2.full_date
        AND COALESCE(t1.calitp_deleted_at, DATE("2099-01-01")) > t2.full_date
        AND t1.day_name = t2.day_name
    WHERE
        # Service date (full_date) must be between service start and end dates
        t1.start_date <= t2.full_date
        AND COALESCE(t1.end_date, DATE("2099-01-01")) >= t2.full_date
  )
SELECT
  *
  , (service_indicator="1" AND NOT COALESCE(service_exclusion, FALSE))
      OR COALESCE(service_inclusion, FALSE)
      AS is_in_service
FROM calendar_daily
FULL JOIN date_include USING(calitp_itp_id, calitp_url_number, service_id, service_date)
FULL JOIN date_exclude USING(calitp_itp_id, calitp_url_number, service_id, service_date)
# TODO: remove hardcoding--set this to be 1 month in the future, etc..
WHERE service_date < DATE_ADD(CURRENT_DATE(), INTERVAL 1 YEAR)
