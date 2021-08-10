---
operator: operators.SqlToWarehouseOperator
dst_table_name: "gtfs_schedule_type2.calitp_feeds"
dependencies:
  - merge_updates
---
With

gtfs_schedule_feed AS (
    SELECT itp_id, url_number, gtfs_schedule_url, agency_name
    FROM `gtfs_schedule_history.tmp_calitp_feeds` T
),
gtfs_schedule_feed_hashed AS (
    SELECT
        *
        , TO_BASE64(MD5(TO_JSON_STRING(T))) AS calitp_hash
    FROM `gtfs_schedule_history.tmp_calitp_feeds` T
),
gtfs_schedule_feed_snapshot AS (
    SELECT itp_id, url_number, gtfs_schedule_url, fn, calitp_hash,
    REGEXP_SUBSTR(fn, "\\d+[-.\\/]\\d+[-.\\/]\\d+") AS calitp_extracted_at
    FROM gtfs_schedule_feed_hashed
),
lag_md5_hash AS (
    SELECT *
    ,DATE(NULL) as calitp_deleted_at
    , LAG(calitp_hash)
        OVER (PARTITION BY itp_id, url_number ORDER BY calitp_extracted_at) AS prev_calitp_hash
        FROM gtfs_schedule_feed_snapshot
),

hash_check AS (
    SELECT *
    , coalesce(calitp_hash!=prev_calitp_hash, true) AS is_changed
    , calitp_extracted_at = MIN(calitp_extracted_at)
    OVER (PARTITION BY itp_id, url_number) AS is_first_extraction,
    from lag_md5_hash
)

SELECT * EXCEPT (calitp_deleted_at),
LEAD (calitp_extracted_at)
OVER (PARTITION BY itp_id ORDER BY calitp_extracted_at) AS calitp_deleted_at
FROM hash_check
