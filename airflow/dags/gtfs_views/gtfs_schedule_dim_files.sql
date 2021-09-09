---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.gtfs_schedule_dim_files"

tests:
  check_null:
    - file_key
  check_unique:
    - file_key
    - file_name

dependencies:
  - dummy_gtfs_schedule_dims
---

WITH

uniq_files AS (
    SELECT DISTINCT name as file_name FROM gtfs_schedule_history.calitp_files_updates
),

dim_files AS (
    SELECT
        file_name AS file_key
        , file_name
        , Config.table_name
        , Config.is_required
        , file_name IS NOT NULL AS is_loadable_file
    FROM uniq_files
    LEFT JOIN `gtfs_schedule_history.calitp_included_gtfs_tables` Config
        USING (file_name)
)

SELECT * FROM dim_files
