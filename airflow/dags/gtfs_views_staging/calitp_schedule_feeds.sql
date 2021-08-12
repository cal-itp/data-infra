---
operator: operators.SqlToWarehouseOperator
dst_table_name: "gtfs_schedule_type2.calitp_feeds"
dependencies:
  - type2_loaded
---

WITH

    gtfs_schedule_feed AS (
        SELECT
            itp_id, url_number, gtfs_schedule_url, agency_name,
            REGEXP_SUBSTR(_FILE_NAME, "(\\d+-\\d+-\\d+)")
              AS calitp_extracted_at
        FROM `gtfs_schedule_history.calitp_feeds` T
    ),
    -- cross unique itp_id, url_number with dates we have for calitp_extracted_at
    -- this will let us detect later on when an entry is missing (e.g. does not exist
    -- for a certain date)
    feed_id_cross_date AS (
        SELECT *
        FROM (SELECT DISTINCT itp_id, url_number FROM gtfs_schedule_feed) T1
        CROSS JOIN (SELECT DISTINCT calitp_extracted_at FROM gtfs_schedule_feed) T2
    ),

    -- Do a concat rather than just md5 on gtfs_schedule_feed as we only want to
    -- hash on those 4 columns (i.e dont want to hash on filename)
    gtfs_schedule_feed_snapshot AS (
        SELECT
            *
            , TO_BASE64(MD5(
                CONCAT(
                    CAST(itp_id AS STRING), "__", CAST(url_number AS STRING), "__",
                    CAST(gtfs_schedule_url AS STRING), "__", CAST(agency_name AS STRING)
                )
              )) AS calitp_hash
        FROM gtfs_schedule_feed
    ),

    lag_md5_hash AS (
        SELECT
            *
            , LAG(calitp_hash)
                OVER (PARTITION BY itp_id, url_number ORDER BY calitp_extracted_at)
              AS prev_calitp_hash
            , calitp_hash IS NULL
              AS is_removed
            , calitp_extracted_at = MIN(calitp_extracted_at)
                OVER (PARTITION BY itp_id, url_number)
              AS is_first_extraction
        FROM gtfs_schedule_feed_snapshot
        RIGHT JOIN feed_id_cross_date USING (itp_id, url_number, calitp_extracted_at)
    ),

    -- Determine whether file at next extraction has changed md5_hash
    -- use coalesce, so that if a file was added, it will be marked as changed

    hash_check AS (
        SELECT *
            , calitp_hash!=prev_calitp_hash OR is_first_extraction
              AS is_changed
        FROM lag_md5_hash
    ),

    -- mark deleted at dates. note that this keeps removed entries so that their
    -- created at dates can be used to mark deleted at for the previous entry.
    feed_snapshot_with_removed AS (
        SELECT
            *
            , LEAD (calitp_extracted_at)
                OVER (PARTITION BY itp_id, url_number ORDER BY calitp_extracted_at)
              AS calitp_deleted_at

        FROM hash_check
        WHERE is_changed OR is_removed
    ),
    final_data AS (
        SELECT
            TO_BASE64(MD5(
                CONCAT(calitp_hash, "__", CAST(calitp_extracted_at AS STRING))
                ))
                AS feed_key
            , itp_id AS calitp_itp_id
            , url_number AS calitp_url_number
            , gtfs_schedule_url
            , calitp_extracted_at
            , calitp_deleted_at
        FROM feed_snapshot_with_removed
        WHERE NOT is_removed
    ),
    exists_in_latest AS (
        SELECT calitp_itp_id, calitp_url_number, true AS exists_in_latest
        FROM final_data
        WHERE calitp_deleted_at IS NULL
    )

SELECT
    T1.*
    , COALESCE(T2.exists_in_latest, false) as exists_in_latest
    , CONCAT(CAST(itp_id AS STRING), "__", CAST(url_number AS STRING)) AS feed_id
    , CONCAT(agency_name, " (", CAST(url_number AS STRING), ")") AS feed_name
FROM final_data T1
LEFT JOIN exists_in_latest T2 USING(calitp_itp_id, calitp_url_number)
