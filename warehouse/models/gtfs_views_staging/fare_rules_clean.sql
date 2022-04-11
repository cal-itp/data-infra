{{ config(materialized='table') }}

WITH type2 as (
    select *
    from {{ source('gtfs_type2', 'fare_rules') }}
)

, fare_rules_clean as (

    -- Trim all string fields
    -- Incoming schema explicitly defined in gtfs_schedule_history external table definition
    -- select distinct because of several instances of full duplicates, ex. ITP ID 294, URL 1 on 2022-03-09
    SELECT DISTINCT
        calitp_itp_id
        , calitp_url_number
        , TRIM(fare_id) as fare_id
        , TRIM(route_id) as route_id
        , TRIM(origin_id) as origin_id
        , TRIM(destination_id) as destination_id
        , TRIM(contains_id) as contains_id
        , calitp_extracted_at
        , calitp_hash
        , FARM_FINGERPRINT(
            CONCAT(CAST(calitp_hash AS STRING), "___",
            CAST(calitp_extracted_at AS STRING)))
            AS fare_rule_key
        , COALESCE(calitp_deleted_at, "2099-01-01") AS calitp_deleted_at
    FROM type2
)

SELECT * FROM fare_rules_clean
