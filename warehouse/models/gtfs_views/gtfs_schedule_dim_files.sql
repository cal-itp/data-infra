WITH calitp_files_updates AS (
    SELECT *
    FROM {{ source('gtfs_schedule_history', 'calitp_files_updates') }}
),
calitp_included_gtfs_tables AS(
    SELECT *
    FROM {{ source('gtfs_schedule_history', 'calitp_files_updates') }}
),

uniq_files AS (
    SELECT DISTINCT name as file_name
    FROM calitp_files_updates
),

gtfs_schedule_dim_files AS (
    SELECT
        file_name AS file_key
        , file_name
        , Config.table_name
        , Config.is_required
        , file_name IS NOT NULL AS is_loadable_file
    FROM uniq_files
    LEFT JOIN calitp_included_gtfs_tables Config
        USING (file_name)
)

SELECT * FROM gtfs_schedule_dim_files
