{{ config(materialized='table') }}

WITH type2 as (
    select *
    from {{ source('gtfs_type2', 'fare_attributes') }}
)

, fare_attributes_clean as (

    -- Trim all string fields
    -- Incoming schema explicitly defined in gtfs_schedule_history external table definition

    SELECT
        calitp_itp_id
        , calitp_url_number
        , TRIM(fare_id) as fare_id
        , TRIM(price) as price
        , TRIM(currency_type) as currency_type
        , TRIM(payment_method) as payment_method
        , TRIM(transfers) as transfers
        , TRIM(agency_id) as agency_id
        , TRIM(transfer_duration) as transfer_duration
        , calitp_extracted_at
        , calitp_hash
        , FARM_FINGERPRINT(CONCAT(CAST(calitp_hash AS STRING), "___", CAST(calitp_extracted_at AS STRING))) AS fare_attribute_key
        , COALESCE(calitp_deleted_at, "2099-01-01") AS calitp_deleted_at
    FROM type2
)

SELECT * FROM fare_attributes_clean
