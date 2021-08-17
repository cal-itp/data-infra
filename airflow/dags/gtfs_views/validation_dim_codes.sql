---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.validation_dim_codes"
external_dependencies:
  - gtfs_views_staging: all
---

-- TODO: if a future version of the validator changes a codes severity
--       we will end up with multiple entries for code (our primary key)
--       we either need to change track this table, or use only the most recent
--       levels of code x severity
SELECT DISTINCT code, severity FROM `gtfs_schedule_type2.validation_notices_clean`
