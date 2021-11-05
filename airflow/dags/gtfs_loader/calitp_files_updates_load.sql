---
operator: operators.SqlToWarehouseOperator
dst_table_name: "gtfs_schedule_history.calitp_files_updates"
depends_on_past: true
dependencies:
  - calitp_files_process
  - latest_only

---

WITH
    # mark files that we currently add to warehouse (e.g. agency.txt)
    loadable_info AS (
        SELECT t1.*, t2.file_name IS NOT NULL AS is_loadable_file
        FROM `gtfs_schedule_history.calitp_files` AS t1
        LEFT JOIN `gtfs_schedule_history.calitp_included_gtfs_tables` AS t2
            ON t1.name=t2.file_name
    ),
    # add previous md5 hash corresponding to each file
    lag_md5_hash AS (
        SELECT
          *
          , LAG(md5_hash)
                OVER (PARTITION BY calitp_itp_id, calitp_url_number, name ORDER BY calitp_extracted_at)
                AS prev_md5_hash
        FROM loadable_info
    ),
    # check whether hashes match
    hash_check AS (
        SELECT
        *
        # Determine whether file at next extraction has changed md5_hash
        # use coalesce, so that if a file was added, it will be marked as changed
        , coalesce(md5_hash!=prev_md5_hash, true) AS is_changed
        , calitp_extracted_at=MIN(calitp_extracted_at)
              OVER (PARTITION BY calitp_itp_id, calitp_url_number)
              AS is_first_extraction
        , name="validation.json" AS is_validation
        FROM lag_md5_hash
)

SELECT
    *
    # Determine whether any hash changed for an agency's extraction files
    , SUM(CAST(is_changed AND is_loadable_file AS INT64))
        OVER (PARTITION BY calitp_itp_id, calitp_url_number, calitp_extracted_at)
        !=0
      AS is_agency_changed
FROM hash_check
