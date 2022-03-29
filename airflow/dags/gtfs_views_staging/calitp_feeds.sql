---
operator: operators.SqlToWarehouseOperator
dst_table_name: "gtfs_views_staging.calitp_feeds"
dependencies:
  - type2_loaded
---

WITH

    gtfs_schedule_feed_snapshot AS (
        SELECT
            itp_id, url_number, gtfs_schedule_url, agency_name, status, calitp_extracted_at
            -- Do a concat rather than just md5 on gtfs_schedule_feed as we only want to
            -- hash on those 5 columns (i.e dont want to hash on extracted at)
            , TO_BASE64(MD5(
                CONCAT(
                    CAST(itp_id AS STRING), "__", CAST(url_number AS STRING), "__",
                    COALESCE(CAST(gtfs_schedule_url AS STRING), "_NULL_"), "__",
                    COALESCE(CAST(agency_name AS STRING), "_NULL_")
                )
              )) AS calitp_hash
            , calitp_extracted_at = MIN(calitp_extracted_at)
                OVER (PARTITION BY itp_id, url_number)
              AS is_first_extraction
        FROM `gtfs_schedule_history.calitp_status` T
    ),
    -- cross unique itp_id, url_number with dates we have for calitp_extracted_at
    -- this will let us detect later on when an entry is missing (e.g. does not exist
    -- for a certain date)
    feed_id_cross_date AS (
        SELECT *
        FROM (SELECT DISTINCT itp_id, url_number FROM gtfs_schedule_feed_snapshot) T1
        CROSS JOIN (SELECT DISTINCT calitp_extracted_at FROM gtfs_schedule_feed_snapshot) T2
    ),

    lag_md5_hash AS (
        SELECT
            *
            , LAG(calitp_hash)
                OVER (PARTITION BY itp_id, url_number ORDER BY calitp_extracted_at)
              AS prev_calitp_hash
            , calitp_hash IS NULL
              AS is_removed
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
            , agency_name AS calitp_agency_name
            , gtfs_schedule_url AS calitp_gtfs_schedule_url
            , calitp_extracted_at
            , COALESCE(calitp_deleted_at, "2099-01-01") AS calitp_deleted_at
        FROM feed_snapshot_with_removed
        WHERE NOT is_removed
    ),
    exists_in_latest AS (
        SELECT calitp_itp_id, calitp_url_number, true AS calitp_id_in_latest
        FROM final_data
        WHERE calitp_deleted_at = "2099-01-01"
    ),
    final AS (
        SELECT
            T1.*
            , COALESCE(T2.calitp_id_in_latest, false) AS calitp_id_in_latest
            , CONCAT(CAST(calitp_itp_id AS STRING), "__", CAST(calitp_url_number AS STRING)) AS calitp_feed_id
            , CONCAT(calitp_agency_name, " (", CAST(calitp_url_number AS STRING), ")") AS calitp_feed_name
        FROM final_data T1
        LEFT JOIN exists_in_latest T2 USING(calitp_itp_id, calitp_url_number)
    )

SELECT * FROM final
