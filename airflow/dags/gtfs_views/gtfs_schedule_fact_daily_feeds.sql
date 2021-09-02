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
        calitp_itp_id,
        calitp_url_number
    FROM `views.gtfs_schedule_dim_feeds` Feeds
    JOIN `views.dim_date` AS D
        ON
            Feeds.calitp_extracted_at <= D.full_date
            AND Feeds.calitp_deleted_at > D.full_date
            AND D.is_in_past_or_present
),

-- join in whether or not a feed download succeeded on a given day

feed_status AS (
    SELECT
        daily_feeds.*
        , CASE WHEN Status.status = "success" THEN "success" ELSE "error"
            END
            AS extraction_status

    FROM daily_feeds
    LEFT JOIN `gtfs_schedule_history.calitp_status` Status
        ON
            daily_feeds.calitp_itp_id = Status.itp_id
            AND daily_feeds.calitp_url_number = Status.url_number
            AND daily_feeds.date = Status.calitp_extracted_at
)

SELECT
    * EXCEPT(calitp_itp_id, calitp_url_number)
FROM feed_status
