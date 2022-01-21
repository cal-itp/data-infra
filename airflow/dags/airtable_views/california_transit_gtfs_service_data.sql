---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.airtable_california_transit_gtfs_service_data"

tests:
  check_null:
    - gtfs_service_data_id
  check_unique:
    - gtfs_service_data_id

external_dependencies:
  - airtable_loader: california_transit_gtfs_service_data
---

  SELECT * FROM `airtable.california_transit_gtfs_service_data`
