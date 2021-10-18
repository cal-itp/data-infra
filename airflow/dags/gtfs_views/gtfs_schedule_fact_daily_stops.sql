---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.gtfs_schedule_fact_daily_feed_stops"

tests:
  check_null:
    - feed_key
    - stop_key
    - date
  check_composite_unique:
    - feed_key
    - stop_key
    - date

dependencies:
  - gtfs_schedule_dim_feeds
  - gtfs_schedule_dim_stops
---


WITH

feed_stops AS (
    SELECT
    T1.feed_key
    , T2.stop_key
    , GREATEST(T1.calitp_extracted_at, T2.calitp_extracted_at) AS calitp_extracted_at
    , LEAST(T1.calitp_deleted_at, T2.calitp_deleted_at) AS calitp_deleted_at
    FROM `views.gtfs_schedule_dim_feeds` T1
    JOIN `views.gtfs_schedule_dim_stops` T2
        USING (calitp_itp_id, calitp_url_number)
    WHERE
        T1.calitp_extracted_at < T2.calitp_deleted_at
        AND T2.calitp_extracted_at < T1.calitp_deleted_at
),

daily_feed_stops AS (
    SELECT
        T1.feed_key
        , T1.stop_key
        , T2.full_date AS date
        , T1.* EXCEPT(feed_key, stop_key)
    FROM feed_stops T1
    JOIN views.dim_date T2
        ON  T1.calitp_extracted_at <= T2.full_date
            AND T1.calitp_deleted_at > T2.full_date
    WHERE T2.full_date <= CURRENT_DATE()
)

SELECT * FROM daily_feed_stops
