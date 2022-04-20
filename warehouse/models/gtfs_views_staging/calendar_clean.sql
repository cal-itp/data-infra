{{ config(materialized='table') }}

WITH calendar AS (
    SELECT *
    FROM {{ source('gtfs_type2', 'calendar') }}
),

calendar_clean AS (

    -- Trim all string fields
    -- Incoming schema explicitly defined in gtfs_schedule_history external table definition

    SELECT
        calitp_itp_id,
        calitp_url_number,
        TRIM(service_id) AS service_id,
        TRIM(monday) AS monday,
        TRIM(tuesday) AS tuesday,
        TRIM(wednesday) AS wednesday,
        TRIM(thursday) AS thursday,
        TRIM(friday) AS friday,
        TRIM(saturday) AS saturday,
        TRIM(sunday) AS sunday,
        PARSE_DATE("%Y%m%d", TRIM(start_date)) AS start_date,
        PARSE_DATE("%Y%m%d", TRIM(end_date)) AS end_date,
        calitp_extracted_at,
        calitp_hash,
        FARM_FINGERPRINT(CONCAT(CAST(calitp_hash AS STRING), "___", CAST(calitp_extracted_at AS STRING)))
        AS calendar_key,
        COALESCE(calitp_deleted_at, "2099-01-01") AS calitp_deleted_at
    FROM calendar
)

SELECT * FROM calendar_clean
