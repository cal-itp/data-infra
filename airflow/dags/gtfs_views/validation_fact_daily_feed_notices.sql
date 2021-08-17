---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.validation_fact_daily_feed_notices"

external_dependencies:
  - gtfs_views_staging: all

dependencies:
  - gtfs_schedule_dim_feeds
---

SELECT
    T2.feed_key
    , D.full_date AS date
    , T1.calitp_extracted_at AS validation_created_at
    , T1.calitp_deleted_at AS validation_deleted_at
    , T1.* EXCEPT (calitp_extracted_at, calitp_deleted_at)

FROM `gtfs_schedule_type2.validation_notices_clean` T1
JOIN `views.dim_date` D
    ON T1.calitp_extracted_at <= D.full_date
        AND T1.calitp_deleted_at > D.full_date
JOIN `views.gtfs_schedule_dim_feeds` T2
    ON T2.calitp_extracted_at <= D.full_date
        AND T2.calitp_deleted_at > D.full_date
        AND T1.calitp_itp_id=T2.calitp_itp_id
        AND T1.calitp_url_number=T2.calitp_url_number
WHERE
    D.full_date < CURRENT_DATE()
