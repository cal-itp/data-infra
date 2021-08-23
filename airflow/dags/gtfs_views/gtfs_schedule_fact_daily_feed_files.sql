---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.gtfs_schedule_fact_daily_feed_files"
dependencies:
  - gtfs_schedule_dim_feeds
---

-- calitp_files_updates tracks daily each file downloaded from a gtfs schedule
-- zip file. It has 1 entry feed downloaded, per file, per day
SELECT
    T2.feed_key
    , T1.name AS file_key
    , T1.calitp_extracted_at AS date
    , T1.size
    , T1.md5_hash
    , T1.is_loadable_file
    , T1.is_changed
    , T1.is_first_extraction
    , T1.is_validation
    , T1.is_agency_changed
    , T1.full_path
FROM `gtfs_schedule_history.calitp_files_updates` T1
JOIN `views.gtfs_schedule_dim_feeds` T2
    USING (calitp_itp_id, calitp_url_number)
WHERE
    T1.calitp_extracted_at >= T2.calitp_extracted_at
    AND T1.calitp_extracted_at < T2.calitp_deleted_at
