{{ config(materialized='table') }}

WITH levels as (
    select *
    from {{ source('gtfs_type2', 'levels') }}
)

, levels_clean as (

    -- Trim all string fields
    -- Incoming schema explicitly defined in gtfs_schedule_history external table definition

    SELECT
        calitp_itp_id
        , calitp_url_number
        , TRIM(level_id) as level_id
        , level_index
        , TRIM(level_name) as level_name
        , calitp_extracted_at
        , calitp_hash
        , FARM_FINGERPRINT(CONCAT(CAST(calitp_hash AS STRING), "___", CAST(calitp_extracted_at AS STRING))) AS level_key
        , COALESCE(calitp_deleted_at, "2099-01-01") AS calitp_deleted_at
    FROM levels
)

SELECT * FROM levels_clean
