---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.gtfs_schedule_dim_routes"

tests:
  check_null:
    - route_key
  check_unique:
    - route_key

dependencies:
  - dummy_gtfs_schedule_dims
---

WITH

-- combine route and agency information. note that agency may be missing from
-- a feed's gtfs data, so we need to take care that the route data makes it
-- into the table no matter what
route_agencies AS (
    SELECT
        T1.* EXCEPT(continuous_pickup, continuous_drop_off, calitp_extracted_at, calitp_deleted_at, calitp_hash)
        , continuous_pickup AS route_continuous_pickup
        , continuous_drop_off AS route_continuous_drop_off
        , T2.* EXCEPT(calitp_itp_id, calitp_url_number, agency_id, calitp_extracted_at, calitp_deleted_at, calitp_hash)
        , COALESCE(GREATEST(T1.calitp_extracted_at, T2.calitp_extracted_at), T1.calitp_extracted_at) AS calitp_extracted_at
        , COALESCE(LEAST(T1.calitp_deleted_at, T2.calitp_deleted_at), T1.calitp_deleted_at) AS calitp_deleted_at
    FROM `gtfs_schedule_type2.routes_clean` T1
    LEFT JOIN `gtfs_schedule_type2.agency_clean` T2
        ON T1.calitp_itp_id = T2.calitp_itp_id
        AND T1.calitp_url_number = T2.calitp_url_number
        AND T1.agency_id = T2.agency_id
        AND T1.calitp_extracted_at < T2.calitp_deleted_at
        AND T2.calitp_extracted_at < T1.calitp_deleted_at
)

SELECT
    FARM_FINGERPRINT(CONCAT(route_key, "___", COALESCE(CAST(agency_key AS STRING), "MISSING"))) AS route_key
    , * EXCEPT (route_key, agency_key)
FROM route_agencies
