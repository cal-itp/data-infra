---
operator: operators.SqlToWarehouseOperator
dst_table_name: "gtfs_schedule_type2.calitp_feeds"
dependencies:
  - merge_updates
---

With
    gtfs_schedule_feed AS (
        SELECT
            itp_id, url_number, gtfs_schedule_url, agency_name,
            REGEXP_SUBSTR(_FILE_NAME, "(\\d+-\\d+-\\d+)")
              AS calitp_extracted_at
        FROM `gtfs_schedule_history.calitp_feeds` T
    ),

--Do a concat rather than just md5 on gtfs_schedule_feed as we only want to
--hash on those 4 columns (i.e dont want to hash on filename)

    gtfs_schedule_feed_snapshot AS (
        SELECT
            *
            , TO_BASE64(MD5(
                CONCAT(
                    CAST(itp_id AS STRING), "__", CAST(url_number AS STRING), "__",
                    CAST(gtfs_schedule_url AS STRING), "__", CAST(agency_name AS STRING)
                )
              )) AS calitp_hash
        FROM
            `gtfs_schedule_feed`
    ),
    lag_md5_hash AS (
        SELECT
            *
        , LAG(calitp_hash)
            OVER (PARTITION BY itp_id, url_number ORDER BY calitp_extracted_at) AS prev_calitp_hash
            FROM gtfs_schedule_feed_snapshot
    ),

 -- Determine whether file at next extraction has changed md5_hash
 -- use coalesce, so that if a file was added, it will be marked as changed

    hash_check AS (
        SELECT *
        , coalesce(calitp_hash!=prev_calitp_hash, true) AS is_changed
        , calitp_extracted_at = MIN(calitp_extracted_at)
        OVER (PARTITION BY itp_id, url_number) AS is_first_extraction,
        from lag_md5_hash
    )
SELECT
    *
    , LEAD (calitp_extracted_at)
        OVER (PARTITION BY itp_id, url_number ORDER BY calitp_extracted_at) AS calitp_deleted_at
    FROM hash_check
    WHERE is_changed
