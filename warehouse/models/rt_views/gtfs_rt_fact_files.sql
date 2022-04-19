{{ config(materialized='table') }}

WITH source AS (
    SELECT *
    FROM {{ source('gtfs_rt_raw', 'calitp_files') }}
),

gtfs_rt_fact_files AS (
    SELECT
        calitp_extracted_at,
        calitp_itp_id,
        calitp_url_number,
        -- turn name from a file path like gtfs_rt_<file_type>_url
        -- to just file_type
        REGEXP_EXTRACT(name, r"gtfs_rt_(.*)_url") AS name,
        size,
        md5_hash,
        DATE(calitp_extracted_at) AS date_extracted,
        EXTRACT(HOUR FROM calitp_extracted_at) AS hour_extracted,
        EXTRACT(MINUTE FROM calitp_extracted_at) AS minute_extracted
    FROM source
)

SELECT * FROM gtfs_rt_fact_files
