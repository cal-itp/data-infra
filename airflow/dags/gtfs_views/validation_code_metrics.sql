---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.validation_code_metrics"
dependencies:

  - warehouse_loaded
  - dim_date
---

WWITH
date_range AS (
    SELECT
        *
        , t2.full_date AS metric_date
    FROM `gtfs_schedule_type2.validation_notices` t1
    JOIN `views.dim_date` t2
    ON t1.calitp_extracted_at <= t2.full_date
        AND COALESCE(t1.calitp_deleted_at, DATE("2099-01-01")) > t2.full_date
        AND t2.full_date <= CURRENT_DATE()
),
unique_codes AS (
      SELECT DISTINCT code FROM `gtfs_schedule_type2.validation_notices`
  ),
  agency_by_code AS (
      SELECT t3.calitp_itp_id, t3.calitp_url_number, t4.code, t5.metric_date
      FROM `views.gtfs_agency_names` t3
      CROSS JOIN unique_codes t4
      CROSS JOIN (SELECT DISTINCT metric_date FROM date_range) t5
  ),
    code_metrics_partial AS (
      SELECT
      calitp_itp_id
      , calitp_url_number
      , metric_date
      , code
      , severity
      , COUNT(*) AS n_notices
  FROM date_range
  GROUP BY 1, 2, 3, 4, 5
    ),
  code_metrics_full AS (
    SELECT 
      * EXCEPT (n_notices)
      , LAG (n_notices)
            OVER (PARTITION BY calitp_itp_id, calitp_url_number, severity, code ORDER BY metric_date)
        AS prev_n_notices
      ,COALESCE(n_notices, 0) as n_notices
    FROM code_metrics_partial  
    LEFT JOIN `agency_by_code` USING (metric_date,calitp_itp_id,calitp_url_number,code)

  )
    SELECT
      * EXCEPT(prev_n_notices)
      , n_notices - prev_n_notices AS diff_n_notices

      FROM code_metrics_full