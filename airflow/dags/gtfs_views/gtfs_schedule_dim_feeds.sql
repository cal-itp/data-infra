---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.gtfs_schedule_dim_feeds"
dependencies:
  - dummy_gtfs_schedule_dims
---

WITH

feed_feed_info AS (
    SELECT
        * EXCEPT(calitp_extracted_at, calitp_deleted_at, calitp_hash)
        -- TODO: MTC 511 is a composite feed, and has multiple feed_info entries,
        -- that join to feed_info -> agency -> routes. However this violates a common
        -- business question, "how many feeds have feed_info.x?", and seems to go
        -- against the data schema. Mark here and remove feed_info for it via where clause
        , IF(T1.calitp_itp_id = 200, TRUE, FALSE)
            AS is_composite_feed
        , GREATEST(T1.calitp_extracted_at, T2.calitp_extracted_at) AS calitp_extracted_at
        , LEAST(T1.calitp_deleted_at, T2.calitp_deleted_at) AS calitp_deleted_at
    FROM `gtfs_schedule_type2.calitp_feeds` T1
    LEFT JOIN `gtfs_schedule_type2.feed_info_clean` T2
        USING (calitp_itp_id, calitp_url_number)
    WHERE
        T1.calitp_extracted_at < T2.calitp_deleted_at
        AND T2.calitp_extracted_at < T1.calitp_deleted_at
        AND T2.calitp_itp_id != 200
)

SELECT
    * EXCEPT(feed_key, feed_info_key)
    , FARM_FINGERPRINT(CONCAT(T.feed_key, "___", T.feed_info_key)) AS feed_key
FROM feed_feed_info T
