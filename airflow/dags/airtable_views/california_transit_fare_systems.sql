---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.airtable_california_transit_fare_systems"

tests:
  check_null:
    - fare_system_id
  check_unique:
    - fare_system_id

external_dependencies:
  - airtable_loader: california_transit_fare_systems
---

  SELECT * FROM `airtable.california_transit_fare_systems`
