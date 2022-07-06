{{ config(materialized='table') }}

WITH translations AS (
    SELECT *
    FROM {{ source('gtfs_type2', 'translations') }}
),

translations_clean AS (

    -- Trim all string fields
    -- Incoming schema explicitly defined in gtfs_schedule_history external table definition


    SELECT
        calitp_itp_id,
        calitp_url_number,
        TRIM(table_name) AS table_name,
        TRIM(field_name) AS field_name,
        TRIM(language) AS language,
        TRIM(translation) AS translation,
        TRIM(record_id) AS record_id,
        TRIM(record_sub_id) AS record_sub_id,
        TRIM(field_value) AS field_value,
        calitp_extracted_at,
        calitp_hash,
        {{ farm_surrogate_key(['calitp_hash', 'calitp_extracted_at']) }} AS translation_key,
        COALESCE(calitp_deleted_at, "2099-01-01") AS calitp_deleted_at
    FROM translations
)

SELECT * FROM translations_clean
