{{ config(materialized='table') }}

WITH transfers AS (
    SELECT *
    FROM {{ source('gtfs_type2', 'transfers') }}
),

transfers_clean AS (

    -- Trim all string fields
    -- Incoming schema explicitly defined in gtfs_schedule_history external table definition
    -- select distinct because of several duplicates, including ITP ID 279 URL 1 on 2022-03-23
    SELECT DISTINCT
        calitp_itp_id,
        calitp_url_number,
        TRIM(from_stop_id) AS from_stop_id,
        TRIM(to_stop_id) AS to_stop_id,
        TRIM(transfer_type) AS transfer_type,
        calitp_extracted_at,
        calitp_hash,
        {{ farm_surrogate_key(['calitp_hash', 'calitp_extracted_at']) }} AS transfer_key,
        COALESCE(calitp_deleted_at, "2099-01-01") AS calitp_deleted_at
    FROM transfers
)

SELECT * FROM transfers_clean
