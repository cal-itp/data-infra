---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.gtfs_schedule_dim_routes"
dependencies:
  - dummy_gtfs_schedule_dims
---

SELECT
    * EXCEPT(continuous_pickup, continuous_drop_off)
    , continuous_pickup AS route_continuous_pickup
    , continuous_drop_off AS route_continuous_drop_off
    , GREATEST(T1.calitp_extracted_at, T2.calitp_extracted_at) AS calitp_extracted_at
    , LEAST(T1.calitp_deleted_at, T2.calitp_deleted_at) AS calitp_deleted_at
FROM `gtfs_schedule_type2.routes_clean` T1
LEFT JOIN `gtfs_schedule_type2.agencies_clean` T2
    USING (calitp_itp_id, calitp_url_number, agency_id)
WHERE
    T1.calitp_extracted_at < T2.calitp_deleted_at
    AND T2.calitp_extracted_at < T1.calitp_deleted_at
