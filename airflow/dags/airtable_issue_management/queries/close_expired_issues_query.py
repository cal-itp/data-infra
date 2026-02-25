CLOSE_EXPIRED_ISSUES_SQL = """
WITH filtered_issues AS (
  SELECT
    source_record_id AS issue_source_record_id,
    gtfs_dataset_source_record_id,
    gtfs_dataset_name,
    outreach_status,
    issue__ AS issue_number
  FROM `mart_transit_database.fct_transit_data_quality_issues`
  WHERE is_open = TRUE
    AND issue_type_name IN (
      'About to Expire Schedule Feed',
      'Expired Schedule Feed',
      'Expiring feed maintained by Cal-ITP'
    )
),

issues_with_urls AS (
  SELECT
    i.*,
    dg.base64_url
  FROM filtered_issues i
  INNER JOIN `mart_transit_database.dim_gtfs_datasets` dg
    ON i.gtfs_dataset_source_record_id = dg.source_record_id
   AND dg._is_current = TRUE
),

issues_with_feed_key AS (
  SELECT
    u.*,
    sf.key AS feed_key
  FROM issues_with_urls u
  INNER JOIN `mart_gtfs.dim_schedule_feeds` sf
    USING (base64_url)
  WHERE sf._is_current = TRUE
),

calendar_max_dates AS (
  SELECT
    feed_key,
    MAX(end_date) AS max_calendar
  FROM `mart_gtfs_schedule_latest.dim_calendar_latest`
  WHERE monday = 1 OR tuesday = 1 OR wednesday = 1
     OR thursday = 1 OR friday = 1 OR saturday = 1 OR sunday = 1
  GROUP BY feed_key
),

calendar_dates_exceptions AS (
  SELECT
    feed_key,
    MAX(date) AS max_calendar_date
  FROM `mart_gtfs_schedule_latest.dim_calendar_dates_latest`
  WHERE exception_type = 1
  GROUP BY feed_key
),

max_service_end_dates AS (
  SELECT
    COALESCE(cd.feed_key, ce.feed_key) AS feed_key,
    GREATEST(
      COALESCE(cd.max_calendar, ce.max_calendar_date),
      COALESCE(ce.max_calendar_date, cd.max_calendar)
    ) AS max_end_date
  FROM calendar_max_dates cd
  FULL OUTER JOIN calendar_dates_exceptions ce
    USING (feed_key)
),

final_filtered_issues AS (
  SELECT
    i.*,
    d.max_end_date AS new_end_date
  FROM issues_with_feed_key i
  LEFT JOIN max_service_end_dates d
    USING (feed_key)
  WHERE DATE_ADD(max_end_date, INTERVAL -30 DAY) > CURRENT_DATE()
)

SELECT
  issue_number,
  issue_source_record_id,
  outreach_status,
  gtfs_dataset_name,
  new_end_date
FROM final_filtered_issues;
"""
