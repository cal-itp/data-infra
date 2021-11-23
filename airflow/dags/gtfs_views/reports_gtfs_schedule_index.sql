---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.reports_gtfs_schedule_index"
description: |
  Agency feed info used to generate monthly reports at reports.calitp.org.

  Each row is a feed from agencies.yml (e.g. itp id, and url number), and includes
  date ranges for reports, and indicators for things that might break a report.
  For example, whether an agency has a feed_info.txt in their data in a given
  reporting period.

fields:
  calitp_itp_id: calitp id
  calitp_url_number: calitp url number
  publish_date: Date a report will be published (e.g. June 1st reports for the month of May)
  date_start: The beginning of the month being reported.
  date_end: The end of the month being reported.
  has_feed_info: Whether the most recent (date_end) feed for a month has feed_info.txt.
  use_for_report: Whether to use to generate a report for this feed on this date.

external_dependencies:
  - gtfs_views_staging: all

dependencies:
  - dim_date
---

WITH
publish_dates AS (
    SELECT
        full_date AS date_start
        , LAST_DAY(full_date, MONTH) AS date_end
        , DATE_ADD(LAST_DAY(full_date, MONTH), INTERVAL 1 DAY) AS publish_date
    FROM `views.dim_date`
    WHERE
        DATE_TRUNC(full_date, MONTH) = full_date
),
publish_dates_crnt AS (
    SELECT * FROM publish_dates
    WHERE publish_date BETWEEN "2021-06-01" AND CURRENT_DATE()
),
# For each publish_date above, check which gtfs data sets have a feed_info
# file in them. Currently, reports will error if this file is missing.
has_feed_info_end_date AS (
    SELECT DISTINCT
        PD.publish_date
        , calitp_itp_id
        , calitp_url_number
        , TRUE AS has_feed_info
    FROM `gtfs_schedule_type2.feed_info_clean` FI
    JOIN publish_dates_crnt PD ON
        FI.calitp_extracted_at <= PD.date_end
        AND COALESCE(FI.calitp_deleted_at, "2099-01-01") > PD.date_end
),
# For each publish date, get the agencies listed in agencies.yml
# on that date. These will be used to generate the reports for that
# month. Critically this will not change over time (whereas using the
# most recent agencies.yml file data would).
agency_feeds_on_end_date AS (
    SELECT
        PD.publish_date
        , S.itp_id AS calitp_itp_id
        , S.url_number AS calitp_url_number
        , S.agency_name
        , COALESCE(FI.has_feed_info, FALSE)
            AS has_feed_info
        # Hardcode certain feeds as private to make sure reports are not generated
        , S.itp_id IN (13, 346) AS is_private_feed
    FROM `gtfs_schedule_history.calitp_status` S
    JOIN publish_dates_crnt PD ON
        S.calitp_extracted_at = PD.date_end
    LEFT JOIN has_feed_info_end_date FI
      ON S.itp_id = FI.calitp_itp_id
         AND S.url_number = FI.calitp_url_number
         AND PD.publish_date = FI.publish_date
)

SELECT
    publish_date
    , calitp_itp_id
    , calitp_url_number
    , AF.agency_name
    , PD.date_start
    , PD.date_end
    , has_feed_info
    , is_private_feed
    , (calitp_url_number = 0
      AND has_feed_info
      AND NOT is_private_feed
      ) AS use_for_report
FROM agency_feeds_on_end_date AF
JOIN publish_dates_crnt PD
  USING (publish_date)
