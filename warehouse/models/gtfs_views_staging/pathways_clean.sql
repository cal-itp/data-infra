{{ config(materialized='table') }}

WITH pathways AS (
    SELECT *
    FROM {{ source('gtfs_type2', 'pathways') }}
),

pathways_clean AS (

    -- Trim all string fields
    -- Incoming schema explicitly defined in gtfs_schedule_history external table definition

    SELECT
        calitp_itp_id,
        calitp_url_number,
        TRIM(pathway_id) AS pathway_id,
        TRIM(from_stop_id) AS from_stop_id,
        TRIM(to_stop_id) AS to_stop_id,
        pathway_mode,
        is_bidirectional,
        length,
        traversal_time,
        stair_count,
        max_slope,
        min_width,
        TRIM(signposted_as) AS signposted_as,
        TRIM(reversed_signposted_as) AS reversed_signposted_as,
        calitp_extracted_at,
        calitp_hash,
        {{ farm_surrogate_key(['calitp_hash', 'calitp_extracted_at']) }} AS pathway_key,
        COALESCE(calitp_deleted_at, "2099-01-01") AS calitp_deleted_at
    FROM pathways
)

SELECT * FROM pathways_clean
