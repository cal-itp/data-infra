---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.gtfs_agency_names"
dependencies:
  - gtfs_status_latest
---

# Note that these entries should be distinct already, but since they're entered
# by hand, we guarantee it by using DISTINCT below.
SELECT DISTINCT
  itp_id as calitp_itp_id
  , url_number as calitp_url_number
  , agency_name
FROM `views.gtfs_status_latest`
