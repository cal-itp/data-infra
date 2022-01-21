---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.airtable_california_transit_gtfs_datasets"

tests:
  check_null:
    - gtfs_dataset_id
  check_unique:
    - gtfs_dataset_id

external_dependencies:
  - airtable_loader: california_transit_gtfs_datasets
---

  SELECT * FROM `airtable.california_transit_gtfs_datasets`
