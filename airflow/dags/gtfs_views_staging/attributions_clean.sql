---
operator: operators.SqlToWarehouseOperator
dst_table_name: "gtfs_views_staging.attributions_clean"
dependencies:
  - type2_loaded
---

-- Trim all string fields
-- Incoming schema explicitly defined in gtfs_schedule_history external table definition

SELECT
    calitp_itp_id
    , calitp_url_number
    , TRIM(organization_name) as organization_name
    , TRIM(attribution_id) as attribution_id
    , TRIM(agency_id) as agency_id
    , TRIM(route_id) as route_id
    , TRIM(trip_id) as trip_id
    , is_producer
    , is_operator
    , is_authority
    , TRIM(attribution_url) as attribution_url
    , TRIM(attribution_email) as attribution_email
    , TRIM(attribution_phone) as attribution_phone
    , calitp_extracted_at
    , calitp_hash
    , FARM_FINGERPRINT(CONCAT(CAST(calitp_hash AS STRING), "___", CAST(calitp_extracted_at AS STRING))) AS attribution_key
    , COALESCE(calitp_deleted_at, "2099-01-01") AS calitp_deleted_at
FROM `gtfs_schedule_type2.attributions`
