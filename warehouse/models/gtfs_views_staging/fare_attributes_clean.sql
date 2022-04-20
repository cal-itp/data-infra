{{ config(materialized='table') }}

WITH fare_attributes AS (
    SELECT *
    FROM {{ source('gtfs_type2', 'fare_attributes') }}
),

fare_attributes_clean AS (

    -- Trim all string fields
    -- Incoming schema explicitly defined in gtfs_schedule_history external table definition

    SELECT
        calitp_itp_id,
        calitp_url_number,
        TRIM(fare_id) AS fare_id,
        TRIM(price) AS price,
        TRIM(currency_type) AS currency_type,
        TRIM(payment_method) AS payment_method,
        TRIM(transfers) AS transfers,
        TRIM(agency_id) AS agency_id,
        TRIM(transfer_duration) AS transfer_duration,
        calitp_extracted_at,
        calitp_hash,
        FARM_FINGERPRINT(CONCAT(CAST(calitp_hash AS STRING), "___", CAST(calitp_extracted_at AS STRING))) AS fare_attribute_key,
        COALESCE(calitp_deleted_at, "2099-01-01") AS calitp_deleted_at
    FROM fare_attributes
)

SELECT * FROM fare_attributes_clean
