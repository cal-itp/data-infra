{{ config(materialized='table') }}

WITH shapes AS (
    SELECT *
    FROM {{ source('gtfs_type2', 'shapes') }}
),

shapes_clean AS (

    -- Trim all string fields
    -- Incoming schema explicitly defined in gtfs_schedule_history external table definition

    SELECT
        calitp_itp_id,
        calitp_url_number,
        TRIM(shape_id) AS shape_id,
        SAFE_CAST(TRIM(shape_pt_lat) AS FLOAT64) AS shape_pt_lat,
        SAFE_CAST(TRIM(shape_pt_lon) AS FLOAT64) AS shape_pt_lon,
        SAFE_CAST(TRIM(shape_pt_sequence) AS INT64) AS shape_pt_sequence,
        SAFE_CAST(TRIM(shape_dist_traveled) AS FLOAT64) AS shape_dist_traveled,
        calitp_extracted_at,
        calitp_hash,
        {{ farm_surrogate_key(['calitp_hash', 'calitp_extracted_at']) }} AS shape_key,
        COALESCE(calitp_deleted_at, "2099-01-01") AS calitp_deleted_at
    FROM shapes
)

SELECT * FROM shapes_clean
