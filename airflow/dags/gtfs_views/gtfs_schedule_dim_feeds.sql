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
)

SELECT
    FARM_FINGERPRINT(CONCAT(
        T.feed_key, "___",
        IFNULL(CAST(T.feed_info_key AS STRING), "NULL")
    )) AS feed_key
    , * EXCEPT(feed_key, feed_info_key)
FROM feed_feed_info T
