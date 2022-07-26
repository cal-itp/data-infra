{{ config(materialized='table') }}

WITH fare_rules AS (
    SELECT *
    FROM {{ source('gtfs_type2', 'fare_rules') }}
),

fare_rules_clean AS (

    -- Trim all string fields
    -- Incoming schema explicitly defined in gtfs_schedule_history external table definition
    -- select distinct because of several instances of full duplicates, ex. ITP ID 294, URL 1 on 2022-03-09
    SELECT DISTINCT
        calitp_itp_id,
        calitp_url_number,
        TRIM(fare_id) AS fare_id,
        TRIM(route_id) AS route_id,
        TRIM(origin_id) AS origin_id,
        TRIM(destination_id) AS destination_id,
        TRIM(contains_id) AS contains_id,
        calitp_extracted_at,
        calitp_hash,
        {{ farm_surrogate_key(['calitp_hash', 'calitp_extracted_at']) }} AS fare_rule_key,
        COALESCE(calitp_deleted_at, "2099-01-01") AS calitp_deleted_at
    FROM fare_rules
)

SELECT * FROM fare_rules_clean
