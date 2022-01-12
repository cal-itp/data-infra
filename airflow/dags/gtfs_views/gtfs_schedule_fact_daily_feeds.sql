---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.gtfs_schedule_fact_daily_feeds"

tests:
  check_null:
    - feed_key
    - date
  check_composite_unique:
    - feed_key
    - date

dependencies:
  - gtfs_schedule_dim_feeds
---

WITH

-- create underlying dimensions: daily feeds

daily_feeds AS (
    SELECT
        Feeds.feed_key,
        D.full_date AS date,

        -- is the feed valid on this date?
        (Feeds.feed_start_date <= full_date AND Feeds.feed_end_date >= full_date)
          AS is_feed_publish_date_valid,

        -- how long until this feed ends?
        DATE_DIFF(Feeds.feed_end_date, D.full_date, DAY)
          AS days_until_feed_end_date,

        -- how long ago did this feed start?
        DATE_DIFF(D.full_date, Feeds.feed_start_date, DAY)
          AS days_from_feed_start_date,

        calitp_itp_id,
        calitp_url_number

    FROM `views.gtfs_schedule_dim_feeds` Feeds
    JOIN `views.dim_date` AS D
        ON
            Feeds.calitp_extracted_at <= D.full_date
            AND Feeds.calitp_deleted_at > D.full_date
            AND D.is_in_past_or_present
),

-- Extract raw feeds URLs

raw_feed_urls AS (
  SELECT
    *,
    PARSE_DATE(
      '%Y-%m-%d',
      REGEXP_EXTRACT(_FILE_NAME, ".*/([0-9]+-[0-9]+-[0-9]+)")
    ) AS extract_date
  FROM gtfs_schedule_history.calitp_feeds_raw
),

-- join in whether or not a feed download succeeded on a given day and also the raw feed
-- URLs

feed_status AS (
    SELECT
        daily_feeds.*,
        CASE WHEN download_status.status = "success" THEN "success" ELSE "error"
            END
            AS extraction_status,
        parse_result.parse_error_encountered,
        raw_feed_urls.gtfs_schedule_url AS raw_gtfs_schedule_url,
        raw_feed_urls.gtfs_rt_vehicle_positions_url AS raw_gtfs_rt_vehicle_positions_url,
        raw_feed_urls.gtfs_rt_service_alerts_url AS raw_gtfs_rt_service_alerts_url,
        raw_feed_urls.gtfs_rt_trip_updates_url AS raw_gtfs_rt_trip_updates_url
    FROM daily_feeds
    LEFT JOIN `gtfs_schedule_history.calitp_status` download_status
        ON
            daily_feeds.calitp_itp_id = download_status.itp_id
            AND daily_feeds.calitp_url_number = download_status.url_number
            AND daily_feeds.date = download_status.calitp_extracted_at
    LEFT JOIN `gtfs_schedule_history.calitp_feed_parse_result` parse_result
        ON
            daily_feeds.calitp_itp_id = parse_result.calitp_itp_id
            AND daily_feeds.calitp_url_number = parse_result.calitp_url_number
            AND daily_feeds.date = parse_result.calitp_extracted_at
    LEFT JOIN raw_feed_urls
        ON
            daily_feeds.calitp_itp_id = raw_feed_urls.itp_id
            AND daily_feeds.calitp_url_number = raw_feed_urls.url_number
            AND daily_feeds.date = raw_feed_urls.extract_date
)

SELECT
    * EXCEPT(calitp_itp_id, calitp_url_number)
FROM feed_status
