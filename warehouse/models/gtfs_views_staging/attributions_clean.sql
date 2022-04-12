{{ config(materialized='table') }}

WITH attributions as (
    select *
    from {{ source('gtfs_type2', 'attributions') }}
)

, attributions_clean as (

    -- Trim all string fields
    -- Incoming schema explicitly defined in gtfs_schedule_history external table definition
    -- select distinct because of duplicates in MTC 511 feed on 2022-03-23
    SELECT DISTINCT
        calitp_itp_id
        , calitp_url_number
        , TRIM(organization_name) as organization_name
        , TRIM(attribution_id) as attribution_id
        , TRIM(agency_id) as agency_id
        , TRIM(route_id) as route_id
        , TRIM(trip_id) as trip_id
        , CAST(TRIM(is_producer) AS INT64) as is_producer
        , CAST(TRIM(is_operator) AS INT64) as is_operator
        , CAST(TRIM(is_authority) AS INT64) as is_authority
        , TRIM(attribution_url) as attribution_url
        , TRIM(attribution_email) as attribution_email
        , TRIM(attribution_phone) as attribution_phone
        , calitp_extracted_at
        , calitp_hash
        , FARM_FINGERPRINT(CONCAT(CAST(calitp_hash AS STRING), "___", CAST(calitp_extracted_at AS STRING))) AS attribution_key
        , COALESCE(calitp_deleted_at, "2099-01-01") AS calitp_deleted_at
    FROM attributions
)

SELECT * FROM attributions_clean
