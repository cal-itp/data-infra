---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.gtfs_schedule_fact_daily_feed_files"

tests:
  check_null:
    - feed_key
    - file_key
    - date
    - md5_hash
  check_composite_unique:
    - feed_key
    - date
    - file_key

dependencies:
  - gtfs_schedule_dim_feeds
---

WITH

-- calitp_files_updates tracks daily each file downloaded from a gtfs schedule
-- zip file. It has 1 entry feed downloaded, per file, per day
raw_daily_files AS (
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

        -- calculate the leading date, so we can fill in missing rows, where
        -- extraction failed to run.
        , LEAD(T1.calitp_extracted_at)
            OVER (PARTITION BY calitp_itp_id, calitp_url_number ORDER BY T1.calitp_extracted_at)
            AS tmp_next_date

    FROM `gtfs_schedule_history.calitp_files_updates` T1
    JOIN `views.gtfs_schedule_dim_feeds` T2
        USING (calitp_itp_id, calitp_url_number)
    WHERE
        T1.calitp_extracted_at >= T2.calitp_extracted_at
        AND T1.calitp_extracted_at < T2.calitp_deleted_at
),

date_range AS (
    SELECT full_date
    FROM `views.dim_date`
    WHERE is_gtfs_schedule_range
),

interp_daily_files AS (
    SELECT
        * EXCEPT(tmp_next_date)
        , Files.date != D.full_date AS is_interpolated
    FROM raw_daily_files Files
    JOIN date_range D
        ON Files.date <= D.full_date
            AND COALESCE(Files.tmp_next_date, "2099-01-01") > D.full_date
)

-- SELECT * FROM interp_daily_files
SELECT * FROM raw_daily_files
