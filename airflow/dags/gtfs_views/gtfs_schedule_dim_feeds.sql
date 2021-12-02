---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.gtfs_schedule_dim_feeds"

tests:
  check_null:
    - feed_key
  check_unique:
    - feed_key

dependencies:
  - dummy_gtfs_schedule_dims
---

WITH

-- Get a list of all the downloaded feeds according to when a unique version of the
-- static feed was downloaded.
feed_feed_info AS (
    SELECT
        T1.calitp_itp_id
        , T1.calitp_url_number
        , * EXCEPT(calitp_itp_id, calitp_url_number, calitp_extracted_at, calitp_deleted_at, calitp_hash)
        -- TODO: MTC 511 is a composite feed, and has multiple feed_info entries,
        -- that join to feed_info -> agency -> routes. However this violates a common
        -- business question, "how many feeds have feed_info.x?", and seems to go
        -- against the data schema. Mark here and remove feed_info for it via where clause
        , IF(T1.calitp_itp_id = 200, TRUE, FALSE)
            AS is_composite_feed
        , COALESCE(GREATEST(T1.calitp_extracted_at, T2.calitp_extracted_at), T1.calitp_extracted_at) AS calitp_extracted_at
        , COALESCE(LEAST(T1.calitp_deleted_at, T2.calitp_deleted_at), T1.calitp_deleted_at) AS calitp_deleted_at
    FROM `gtfs_schedule_type2.calitp_feeds` T1
    LEFT JOIN `gtfs_schedule_type2.feed_info_clean` T2
        ON
            T1.calitp_itp_id = T2.calitp_itp_id
            AND T1.calitp_url_number = T2.calitp_url_number
            AND T1.calitp_extracted_at < T2.calitp_deleted_at
            AND T2.calitp_extracted_at < T1.calitp_deleted_at
            AND T2.calitp_itp_id != 200
),

-- Get a list of all the the raw feed data (containg info on raw feed URLs for both
-- static and RT feeds) including the extract date of these feeds according to their
-- filename.
raw_feed_with_extract_date AS (
  SELECT
    *,
    PARSE_DATE(
      '%Y-%m-%d',
      REGEXP_EXTRACT(_FILE_NAME, ".*/([0-9]+-[0-9]+-[0-9]+)")
    ) AS extract_date
  FROM gtfs_schedule_history.calitp_feeds_raw
),

-- Join the feed info on the raw extract date. This creates many matches since there
-- will be intermediate raw feed extract dates within the feed info records between
-- their extracted_at / deleted_at ranges
feed_info_raw_feed_join_all AS (
  SELECT
    T1.*
    , T2.gtfs_schedule_url AS raw_gtfs_schedule_url
    , T2.gtfs_rt_vehicle_positions_url AS raw_gtfs_rt_vehicle_positions_url
    , T2.gtfs_rt_service_alerts_url AS raw_gtfs_rt_service_alerts_url
    , T2.gtfs_rt_trip_updates_url AS raw_gtfs_rt_trip_updates_url
    , T2.extract_date AS raw_feeds_extract_date
  FROM feed_feed_info T1
  LEFT JOIN raw_feed_with_extract_date T2
    ON
      T1.calitp_itp_id = T2.itp_id
      AND T1.calitp_url_number = T2.url_number
      AND T1.calitp_extracted_at <= T2.extract_date
      -- Exclude raw feed records on the exact deleted_at date since it is assumed that
      -- the raw feed URL is potentially no longer valid once the valid range has ended.
      AND T1.calitp_deleted_at > T2.extract_date
),

-- Isolate to only the maximum raw feeds extract date within each valid feed period.
last_raw_feeds_extract_date AS (
  SELECT max(raw_feeds_extract_date) AS max_raw_feeds_extract_date,
    calitp_itp_id,
    calitp_url_number,
    calitp_extracted_at,
    calitp_deleted_at
  FROM feed_info_raw_feed_join_all
  GROUP BY calitp_itp_id,
    calitp_url_number,
    calitp_extracted_at,
    calitp_deleted_at
),

-- Pare down the feed_info_raw_feed_join_all query results to only include matches
-- upon the matched maximum raw feeds extract date or records where both the raw feed
-- extract date and max raw feed extract date are null.
final_feed_info AS (
  SELECT T1.*
  FROM feed_info_raw_feed_join_all AS T1,
    last_raw_feeds_extract_date T2
  WHERE
    T1.calitp_itp_id = T2.calitp_itp_id
    AND T1.calitp_url_number = T2.calitp_url_number
    AND T1.calitp_extracted_at = T2.calitp_extracted_at
    AND T1.calitp_deleted_at = T2.calitp_deleted_at
    AND (
      (T1.raw_feeds_extract_date IS NULL AND T2.max_raw_feeds_extract_date IS NULL)
      OR T1.raw_feeds_extract_date = T2.max_raw_feeds_extract_date
    )
)

SELECT
    FARM_FINGERPRINT(CONCAT(
        T.feed_key, "___",
        IFNULL(CAST(T.feed_info_key AS STRING), "NULL")
    )) AS feed_key
    , * EXCEPT(feed_key, feed_info_key)
FROM final_feed_info T
